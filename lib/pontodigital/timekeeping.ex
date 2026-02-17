defmodule Pontodigital.Timekeeping do
  @moduledoc """
  Contexto responsável pelo domínio de Gestão de Tempo.

  Este módulo gerencia o ciclo de vida dos registros de ponto (`ClockIn`),
  o cálculo de saldos, abonos, feriados e a geração do espelho mensal.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Repo
  alias Ecto.Multi
  alias Pontodigital.Timekeeping.ClockIn
  alias Pontodigital.Timekeeping.ClockInAdjustment
  alias Pontodigital.Company.Employee
  alias Pontodigital.Timekeeping.Absence
  alias Pontodigital.Timekeeping.Vacation
  alias Pontodigital.Timekeeping.Holiday
  alias Pontodigital.Timekeeping.Calculator
  alias Pontodigital.Timekeeping.DailyLog

  @doc """
  Busca os registros de ponto de um funcionário para um mês e ano específicos.

  Esta função calcula automaticamente o intervalo de datas (início e fim do mês) e converte
  para UTC antes de realizar a consulta, garantindo que fusos horários sejam respeitados.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `year`: Ano (inteiro).
  - `month`: Mês (inteiro).

  ## Retorno
  - `[%ClockIn{}]`: Lista de registros ordenada por data.
  """
  def get_monthly_clock_ins(employee_id, year, month) do
    start_date = Date.new!(year, month, 1)

    end_date = Date.end_of_month(start_date)

    list_clock_ins_by_employee(employee_id, start_date, end_date)
  end

  defp list_clock_ins_by_employee(employee_id, start_date, end_date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(start_date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(end_date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.employee_id == ^employee_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  @doc """
  Retorna os registros de ponto de um funcionário em um dia específico.

  ## Processamento de Fuso Horário
  Considera o dia civil no fuso `America/Sao_Paulo`.
  A função converte o início (00:00:00) e o fim (23:59:59) desse dia local para UTC
  para filtrar corretamente no banco de dados.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `date`: Data (`Date`) a ser consultada.

  ## Retorno
  - `[%ClockIn{}]`: Lista de registros do dia.
  """
  def list_clock_ins_by_user_in_day(employee_id, date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.employee_id == ^employee_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  @doc """
  Recupera o último registro de ponto válido de um funcionário.

  ## Critérios
  - Filtra apenas registros com status `:valid`.
  - Utilizado principalmente para determinar o estado atual do funcionário (se está trabalhando, em almoço, etc).
  - Base para validação de sequência de batidas.

  ## Parâmetros
  - `employee`: Struct `%Employee{}`.

  ## Retorno
  - `%ClockIn{}`: Último registro encontrado.
  - `nil`: Se o funcionário nunca bateu ponto.
  """
  def get_last_clock_in_by_employee(%Employee{} = employee) do
    get_last_clock_in_by_employee_id(employee.id)
  end

  defp get_last_clock_in_by_employee_id(employee_id) do
    ClockIn
    |> where(employee_id: ^employee_id)
    |> where([c], c.status == :valid)
    |> order_by(desc: :timestamp)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Registra um novo ponto eletrônico, garantindo a consistência temporal e as regras de negócio.

  A operação é atômica (envolvida numa transação de banco de dados).

  ## Regras de Negócio (Invariantes)
  1. **Unicidade:** Não permite registros duplicados do mesmo tipo no mesmo dia.
  2. **Sequencialidade:** Valida estritamente a ordem `:entrada` -> `:ida_almoco` -> `:retorno_almoco` -> `:saida`.
  3. **Limite de Dia:** Detecta automaticamente a virada do dia (baseado em `America/Sao_Paulo`). O primeiro registro de um novo dia deve ser obrigatoriamente uma `:entrada`.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `type`: O tipo de batida (ex: `:entrada`).

  ## Retorno
  - `{:ok, %ClockIn{}}`: Sucesso.
  - `{:error, reason}`: Violação de regra de negócio (átomo) ou tupla com mensagem.
  - `{:error, changeset}`: Erro de validação de dados.
  """
  def register_clock_in(employee_id, type) do
    Repo.transaction(fn ->
      with {:ok, _} <- validate_no_duplicates(employee_id, type),
           last_clock <- get_last_clock_in_by_employee_id(employee_id),
           :ok <- validate_sequence(last_clock, type),
           attrs <- build_attrs(employee_id, type),
           {:ok, clock_in} <- create_clock_in(attrs) do
        clock_in
      else
        {:error, reason} when is_atom(reason) ->
          Repo.rollback(reason)

        {:error, reason, message} ->
          Repo.rollback({reason, message})

        {:error, %Ecto.Changeset{} = changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, clock_in} ->
        {:ok, clock_in}

      {:error, {reason, message}} when is_atom(reason) ->
        {:error, reason, message}

      {:error, reason} when is_atom(reason) ->
        {:error, reason}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  defp validate_no_duplicates(employee_id, type) do
    today = Date.utc_today()

    query =
      from c in ClockIn,
        where: c.employee_id == ^employee_id,
        where: fragment("DATE(?)", c.timestamp) == ^today,
        where: c.type == ^type,
        where: c.status != :invalid

    case Repo.exists?(query) do
      false -> {:ok, :no_duplicates}
      true -> {:error, :duplicate_entry}
    end
  end

  defp build_attrs(employee_id, type) do
    %{
      employee_id: employee_id,
      timestamp: DateTime.utc_now(),
      type: type,
      origin: :web,
      status: :valid
    }
  end

  @doc """
  Retorna uma lista de tipos de batida permitidos para o funcionário no momento atual.

  ## Lógica de Decisão
  Analisa o último ponto registrado:
  - Se for um **novo dia** ou sem registros anteriores: Permite apenas `[:entrada]`.
  - Se o último foi `:entrada`: Permite `[:ida_almoco, :saida]`.
  - Se o último foi `:ida_almoco`: Permite `[:retorno_almoco]`.
  - Se o último foi `:retorno_almoco`: Permite `[:saida]`.
  - Se o último foi `:saida`: Permite `[:entrada]` (início de hora extra ou novo turno).

  ## Parâmetros
  - `employee_id`: ID do funcionário.

  ## Retorno
  - `[:atom]`: Lista de átomos permitidos (ex: `[:ida_almoco, :saida]`).
  """
  def get_allowed_types(employee_id) do
    last_clock = get_last_clock_in_by_employee_id(employee_id)

    if new_day?(last_clock) do
      [:entrada]
    else
      case last_clock.type do
        :entrada -> [:ida_almoco, :saida]
        :ida_almoco -> [:retorno_almoco]
        :retorno_almoco -> [:saida]
        :saida -> [:entrada]
        _ -> [:entrada]
      end
    end
  end

  defp validate_sequence(nil, :entrada), do: :ok

  defp validate_sequence(nil, _),
    do: {:error, :invalid_sequence, "Você deve fazer uma entrada primeiro."}

  defp validate_sequence(last_clock, new_type) do
    is_new = new_day?(last_clock)

    cond do
      is_new and new_type == :entrada ->
        :ok

      is_new ->
        {:error, :invalid_sequence,
         "Novo dia detectado. O primeiro registro de hoje deve ser Entrada."}

      true ->
        validate_same_day_sequence(last_clock.type, new_type)
    end
  end

  defp new_day?(nil), do: true

  defp new_day?(last_clock) do
    timezone = "America/Sao_Paulo"
    {:ok, now} = DateTime.now(timezone)
    today = DateTime.to_date(now)

    {:ok, last_clock_local} = DateTime.shift_zone(last_clock.timestamp, timezone)
    last_clock_date = DateTime.to_date(last_clock_local)

    Date.compare(today, last_clock_date) == :gt
  end

  defp validate_same_day_sequence(:entrada, type) when type in [:saida, :ida_almoco],
    do: :ok

  defp validate_same_day_sequence(:ida_almoco, :retorno_almoco), do: :ok
  defp validate_same_day_sequence(:retorno_almoco, :saida), do: :ok
  defp validate_same_day_sequence(:saida, :entrada), do: :ok

  defp validate_same_day_sequence(nil, :entrada), do: :ok

  defp validate_same_day_sequence(nil, _),
    do: {:error, :invalid_sequence, "Você deve fazer uma entrada primeiro."}

  defp validate_same_day_sequence(last_type, _type) do
    {:error, :invalid_sequence,
     "Sequência inválida para hoje! O último registro foi: #{format_type(last_type)}"}
  end

  defp format_type(:entrada), do: "Entrada"
  defp format_type(:saida), do: "Saída"
  defp format_type(:ida_almoco), do: "Ida para Almoço"
  defp format_type(:retorno_almoco), do: "Retorno do Almoço"
  defp format_type(nil), do: "Nenhum"
  defp format_type(other), do: Atom.to_string(other)

  defp list_timesheet(employee_id, year, month, timezone) do
    start_date = Date.new!(year, month, 1)
    end_date = Date.end_of_month(start_date)

    from_utc =
      Timex.to_datetime(start_date, timezone)
      |> Timex.beginning_of_day()
      |> Timex.to_datetime("UTC")

    to_utc =
      Timex.to_datetime(end_date, timezone)
      |> Timex.end_of_day()
      |> Timex.to_datetime("UTC")

    query =
      from c in ClockIn,
        where: c.employee_id == ^employee_id,
        where: c.timestamp >= ^from_utc and c.timestamp <= ^to_utc,
        where: c.status == :valid,
        order_by: [asc: c.timestamp]

    Repo.all(query)
    |> organize_by_day(timezone)
  end

  defp organize_by_day(clock_ins, timezone) do
    clock_ins
    |> Enum.map(fn clock_in ->
      local_datetime = Timex.to_datetime(clock_in.timestamp, timezone)

      %{
        original: clock_in,
        type: clock_in.type,
        date: Timex.to_date(local_datetime),
        time: Timex.format!(local_datetime, "{h24}:{m}")
      }
    end)
    |> Enum.group_by(fn item -> item.date end)
    |> Map.new(fn {date, points_list} ->
      points_map = %{
        entrada: Enum.find(points_list, fn p -> p.type == :entrada end),
        ida_almoco: Enum.find(points_list, fn p -> p.type == :ida_almoco end),
        retorno_almoco: Enum.find(points_list, fn p -> p.type == :retorno_almoco end),
        saida: Enum.find(points_list, fn p -> p.type == :saida end)
      }

      {date, points_map}
    end)
  end

  @doc """
  Busca um registro de ponto específico pelo ID.

  ## Parâmetros
  - `id`: ID do registro de ponto.

  ## Retorno
  - `%ClockIn{}`: Registro encontrado.
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrado.
  """
  def get_clock_in!(id), do: Repo.get!(ClockIn, id)

  defp create_clock_in(attrs) do
    %ClockIn{}
    |> ClockIn.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Realiza uma edição administrativa (correção) em um registro de ponto existente.

  ## Auditoria e Efeitos Colaterais
  Esta função preserva a integridade histórica:
  1. **Não apaga** o histórico original.
  2. Cria um registro em `clock_in_adjustments` contendo o valor anterior, o ID do admin e a justificativa.
  3. Marca o registro `ClockIn` original com a flag `is_edited: true`.

  ## Parâmetros
  - `clock_in`: Registro original a ser editado.
  - `attrs`: Novos atributos (ex: novo horário).
  - `admin_id`: ID do usuário administrador que está realizando a ação.

  ## Retorno
  - `{:ok, %{clock_in: %ClockIn{}, adjustment: %ClockInAdjustment{}}}`: Sucesso.
  - `{:error, step, changeset, ...}`: Erro na transação.
  """
  def admin_update_clock_in(%ClockIn{} = clock_in, attrs, admin_id) do
    adjustment_attrs = %{
      "clock_in_id" => clock_in.id,
      "admin_user_id" => admin_id,
      "previous_timestamp" => clock_in.timestamp,
      "previous_type" => clock_in.type,
      "justification" => attrs["justification"],
      "observation" => attrs["observation"]
    }

    clock_in_changeset = ClockIn.changeset(clock_in, Map.put(attrs, "is_edited", true))

    adjustment_changeset = ClockInAdjustment.changeset(%ClockInAdjustment{}, adjustment_attrs)

    Multi.new()
    |> Multi.update(:clock_in, clock_in_changeset)
    |> Multi.insert(:adjustment, adjustment_changeset)
    |> Repo.transaction()
  end

  @doc """
  Cria um registro de ponto manualmente (inserção retroativa) por um administrador.

  Diferente do registro comum, este método exige justificativa e cria imediatamente
  um registro de auditoria (`ClockInAdjustment`) vinculado à criação.

  ## Campos Especiais
  - `origin`: Definido automaticamente como `:manual` se não informado.
  - `is_edited`: Definido como `true` para indicar intervenção manual.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `attrs`: Atributos do ponto (timestamp, type, justification, observation).
  - `admin_id`: ID do administrador.

  ## Retorno
  - `{:ok, %{clock_in: %ClockIn{}, adjustment: %ClockInAdjustment{}}}`: Sucesso.
  - `{:error, ...}`: Falha na validação ou transação.
  """
  def admin_create_clock_in(employee_id, attrs, admin_id) do
    clock_in_attrs = %{
      "employee_id" => employee_id,
      "timestamp" => attrs["timestamp"],
      "type" => attrs["type"],
      "origin" => attrs["origin"] || :manual,
      "status" => :valid,
      "is_edited" => true
    }

    Multi.new()
    |> Multi.insert(:clock_in, ClockIn.changeset(%ClockIn{}, clock_in_attrs))
    |> Multi.run(:adjustment, fn repo, %{clock_in: clock_in} ->
      adjustment_attrs = %{
        "clock_in_id" => clock_in.id,
        "admin_user_id" => admin_id,
        "justification" => attrs["justification"],
        "observation" => attrs["observation"],
        "previous_timestamp" => nil,
        "previous_type" => nil
      }

      %ClockInAdjustment{}
      |> ClockInAdjustment.changeset(adjustment_attrs)
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  @doc """
  Invalida (anula) um registro de ponto existente.

  Em vez de deletar o registro do banco, altera seu `status` para `:invalid`.
  Isso garante que o registro não seja contabilizado nos cálculos, mas mantenha
  o rastro de que ele existiu.
  Gera registro de auditoria com a justificativa.

  ## Parâmetros
  - `clock_in`: O registro a ser invalidado.
  - `justification`: Motivo da invalidação.
  - `observation`: Detalhes adicionais.
  - `admin_id`: ID do administrador.

  ## Retorno
  - `{:ok, map}`: Sucesso.
  - `{:error, ...}`: Falha.
  """
  def invalidate_clock_in(%ClockIn{} = clock_in, justification, observation, admin_id) do
    adjustment_attrs = %{
      "clock_in_id" => clock_in.id,
      "admin_user_id" => admin_id,
      "previous_timestamp" => clock_in.timestamp,
      "previous_type" => clock_in.type,
      "justification" => justification,
      "observation" => observation
    }

    Multi.new()
    |> Multi.update(:clock_in, ClockIn.changeset(clock_in, %{status: :invalid}))
    |> Multi.insert(
      :adjustment,
      ClockInAdjustment.changeset(%ClockInAdjustment{}, adjustment_attrs)
    )
    |> Repo.transaction()
  end

  @doc """
  Retorna um changeset para criar ou atualizar um ajuste de ponto (`ClockInAdjustment`).
  Utilizado para validação em formulários administrativos.

  ## Retorno
  - `%Ecto.Changeset{}`
  """
  def change_adjustment(%ClockInAdjustment{} = adjustment, attrs \\ %{}) do
    ClockInAdjustment.changeset(adjustment, attrs)
  end

  # Abono de faltas

  @doc """
  Registra um abono de falta para um funcionário.
  Utilizado para justificar ausências (ex: atestado médico) e evitar desconto
  no banco de horas ou folha de pagamento.

  ## Parâmetros
  - `attrs`: Map com `date`, `reason`, `employee_id`, etc.

  ## Retorno
  - `{:ok, %Absence{}}`: Sucesso.
  - `{:error, changeset}`: Erro de validação.
  """
  def create_absence(attrs) do
    %Absence{}
    |> Absence.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Mapeia todos os abonos de um funcionário dentro de um período.

  ## Retorno Otimizado
  Retorna um mapa `%{Date => Absence}` para acesso rápido (O(1)) durante
  o processamento do espelho de ponto (`get_monthly_report`), evitando iterações desnecessárias.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `start_date`: Início do período (`Date`).
  - `end_date`: Fim do período (`Date`).

  ## Retorno
  - `%{Date => %Absence{}}`: Mapa de abonos indexado pela data.
  """
  def list_absences_map(employee_id, start_date, end_date) do
    from(a in Absence,
      where: a.employee_id == ^employee_id,
      where: a.date >= ^start_date and a.date <= ^end_date
    )
    |> Repo.all()
    |> Map.new(fn absence -> {absence.date, absence} end)
  end

  @doc """
  Remove permanentemente um abono do sistema.
  Geralmente utilizado quando um abono foi lançado por engano pelo administrador.

  ## Retorno
  - `{:ok, %Absence{}}`: Sucesso.
  - `{:error, changeset}`: Falha.
  """
  def delete_absence(%Absence{} = absence) do
    Repo.delete(absence)
  end

  @doc """
  Busca um abono específico pelo ID.

  ## Retorno
  - `%Absence{}`
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrado.
  """
  def get_absence!(id), do: Repo.get!(Absence, id)

  # Feriados
  @doc """
  Lista feriados em um intervalo, retornando um mapa para consulta rápida.

  ## Formato do Retorno
  `%{Date => String (Nome do Feriado)}`.
  Utilizado para identificar dias em que a meta de trabalho deve ser zerada no cálculo do espelho.

  ## Parâmetros
  - `start_date`: Início do período.
  - `end_date`: Fim do período.

  ## Retorno
  - `%{Date => String}`: Mapa de datas para nomes de feriados.
  """
  def list_holidays_map(start_date, end_date) do
    from(h in Holiday,
      where: h.date >= ^start_date and h.date <= ^end_date,
      select: {h.date, h.name}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Cria um novo feriado no sistema.
  Os feriados criados afetam o cálculo de horas de todos os funcionários.

  ## Parâmetros
  - `attrs`: Map com `date` e `name`.

  ## Retorno
  - `{:ok, %Holiday{}}`: Sucesso.
  - `{:error, changeset}`: Erro.
  """
  def create_holiday(attrs) do
    %Holiday{}
    |> Holiday.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retorna um changeset para criar ou atualizar um feriado.
  """
  def change_holiday(%Holiday{} = holiday, attrs \\ %{}) do
    Holiday.changeset(holiday, attrs)
  end

  @doc """
  Remove permanentemente um feriado do sistema.

  ## Retorno
  - `{:ok, %Holiday{}}`: Sucesso.
  """
  def delete_holiday(%Holiday{} = holiday) do
    Repo.delete(holiday)
  end

  @doc """
  Retorna a lista completa de feriados cadastrados, ordenada por data.

  ## Retorno
  - `[%Holiday{}]`
  """
  def list_all_holidays do
    Repo.all(from h in Holiday, order_by: [asc: h.date])
  end

  @doc """
  Busca um feriado específico pelo ID.
  """
  def get_holiday!(id), do: Repo.get!(Holiday, id)

  # Vacation
  @doc """
  Registra um período de férias para um funcionário.

  ## Parâmetros
  - `attrs`: Map com `start_date`, `end_date`, `employee_id`.

  ## Retorno
  - `{:ok, %Vacation{}}`: Sucesso.
  - `{:error, changeset}`: Erro.
  """
  def create_vacation(attrs) do
    %Vacation{}
    |> Vacation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Busca um registro de férias específico pelo ID.
  """
  def get_vacation!(id) do
    Vacation
    |> Repo.get!(id)
  end

  @doc """
  Remove um registro de férias do sistema.

  ## Retorno
  - `{:ok, %Vacation{}}`: Sucesso.
  """
  def delete_vacation(%Vacation{} = vacation) do
    Repo.delete(vacation)
  end

  @doc """
  Mapeia os dias de férias de um funcionário dentro de um período de relatório.

  ## Complexidade
  Férias são persistidas como intervalos (`start_date` a `end_date`).
  Esta função "explode" esses intervalos em dias individuais dentro do mês solicitado,
  retornando um mapa `%{Date => Vacation}`.
  Isso permite que o gerador de relatório verifique dia-a-dia se o funcionário estava de férias.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `start_date`: Início do período.
  - `end_date`: Fim do período.

  ## Retorno
  - `%{Date => %Vacation{}}`: Mapa indexado por dia.
  """
  def list_vacations_map(employee_id, start_date, end_date) do
    query =
      from v in Vacation,
        where: v.employee_id == ^employee_id,
        where: v.start_date <= ^end_date and v.end_date >= ^start_date

    vacations = Repo.all(query)

    Enum.reduce(vacations, %{}, fn vacation, acc ->
      range = Date.range(vacation.start_date, vacation.end_date)

      relevant_range =
        Enum.filter(range, fn date ->
          Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
        end)

      Enum.reduce(relevant_range, acc, fn date, map_acc ->
        Map.put(map_acc, date, vacation)
      end)
    end)
  end

  @doc """
  Gera o relatório completo (espelho de ponto) de um funcionário para um mês específico.

  Esta função agrega dados de 5 fontes diferentes para compor a visualização diária:
  1. **Pontos Batidos:** Os registros brutos.
  2. **Abonos:** Faltas justificadas.
  3. **Feriados:** Dias não úteis nacionais/locais.
  4. **Férias:** Períodos de ausência remunerada.
  5. **Diário de Bordo:** Anotações do funcionário.

  ## Processamento
  Para cada dia do mês, o sistema:
  - Carrega a carga horária esperada (`daily_meta`).
  - Calcula o saldo do dia (crédito ou débito) usando `Calculator`.
  - Resolve registros faltantes (ex: decidir se desconta falta ou se é feriado).

  ## Parâmetros
  - `employee`: Struct completa do funcionário (com `work_schedule` precarregado).
  - `date`: Uma data dentro do mês desejado (ex: `Date.utc_today()`).

  ## Retorno
  Retorna um mapa contendo:
  - `:days`: Lista detalhada dia a dia.
  - `:total_minutes`: Saldo líquido total do mês em minutos.
  - `:formatted_total`: String formatada (ex: `"+05:30"`).
  """
  def get_monthly_report(employee, date) do
    month_range = build_month_range(date)

    processed_days =
      employee
      |> load_context_data(month_range)
      |> process_month_days(month_range, employee)

    total_minutes = calculate_total_balance(processed_days)

    %{
      days: processed_days,
      total_minutes: total_minutes,
      formatted_total: Calculator.format_balance(total_minutes)
    }
  end

  defp build_month_range(date) do
    Date.range(Date.beginning_of_month(date), Date.end_of_month(date))
  end

  defp load_context_data(employee, range) do
    %{
      points:
        list_timesheet(employee.id, range.first.year, range.first.month, "America/Sao_Paulo"),
      absences: list_absences_map(employee.id, range.first, range.last),
      holidays: list_holidays_map(range.first, range.last),
      vacations: list_vacations_map(employee.id, range.first, range.last),
      daily_logs: list_daily_logs_map(employee.id, range.first, range.last)
    }
  end

  defp process_month_days(context, range, employee) do
    daily_meta = get_daily_meta(employee)

    Enum.map(range, fn date ->
      points = Map.get(context.points, date, %{})
      absence = Map.get(context.absences, date)
      holiday = Map.get(context.holidays, date)
      vacation = Map.get(context.vacations, date)
      daily_log = Map.get(context.daily_logs, date)

      {balance_minutes, balance_visual, worked_minutes} =
        calculate_day_balance(points, daily_meta, absence, holiday, vacation, employee, date)

      %{
        date: date,
        points: points,
        abono: absence,
        feriado: holiday,
        ferias: vacation,
        daily_log: daily_log,
        saldo_minutos: balance_minutes,
        saldo_visual: balance_visual,
        trabalhado_minutos: worked_minutes,
        is_weekend: weekend?(date)
      }
    end)
  end

  defp get_daily_meta(%{work_schedule: %Ecto.Association.NotLoaded{}}), do: 480
  defp get_daily_meta(%{work_schedule: nil}), do: 480
  defp get_daily_meta(%{work_schedule: ws}), do: ws.daily_hours * 60

  defp calculate_day_balance(points, meta, absence, holiday, vacation, employee, date) do
    result = Calculator.calculate_daily_balance(points, meta, absence, holiday, vacation)

    case result do
      {:missing_records, default_debit, default_worked} ->
        resolve_missing_records(default_debit, default_worked, employee, date, holiday, vacation)

      result_ok ->
        result_ok
    end
  end

  defp resolve_missing_records(debit, worked, employee, date, holiday, vacation) do
    case should_charge_absence?(employee, date, holiday, vacation) do
      true ->
        {debit, Calculator.format_balance(debit), worked}

      false ->
        {0, "--:--", 0}
    end
  end

  defp should_charge_absence?(employee, date, holiday_name, vacation) do
    not_holiday = is_nil(holiday_name)
    not_vacation = is_nil(vacation)
    is_working_day = check_working_day(employee, date)
    is_hired = Date.compare(date, employee.admission_date) != :lt
    past_or_today = Date.compare(date, Date.utc_today()) != :gt

    not_holiday and not_vacation and is_working_day and is_hired and past_or_today
  end

  defp check_working_day(%{work_schedule: nil}, date), do: not weekend?(date)
  defp check_working_day(%{work_schedule: ws}, date), do: Date.day_of_week(date) in ws.work_days

  defp weekend?(date), do: Date.day_of_week(date) in [6, 7]

  defp calculate_total_balance(days) do
    Enum.reduce(days, 0, fn day, acc -> acc + day.saldo_minutos end)
  end

  # Daily logs
  @doc """
  Busca o registro de atividades (diário) de um funcionário para uma data específica.

  ## Parâmetros
  - `employee_id`: ID do funcionário.
  - `date`: Data do log.

  ## Retorno
  - `%DailyLog{}`: Se encontrado.
  - `nil`: Se nenhum registro for encontrado para o dia.
  """
  def get_daily_log(employee_id, date) do
    Repo.get_by(DailyLog, employee_id: employee_id, date: date)
  end

  @doc """
  Persiste ou atualiza o diário de bordo de um dia (Upsert).

  ## Comportamento
  Verifica se já existe um log para o `employee_id` e `date` informados:
  - **Se existir:** Atualiza o registro existente.
  - **Se não existir:** Cria um novo registro.

  ## Parâmetros
  - `attrs`: Map com `employee_id`, `date` e campos do log.

  ## Retorno
  - `{:ok, %DailyLog{}}`: Sucesso.
  - `{:error, changeset}`: Erro.
  """
  def save_daily_log(attrs) do
    employee_id = attrs["employee_id"] || attrs[:employee_id]
    date = attrs["date"] || attrs[:date]

    case get_daily_log(employee_id, date) do
      nil ->
        %DailyLog{}
        |> DailyLog.changeset(attrs)
        |> Repo.insert()

      existing_log ->
        existing_log
        |> DailyLog.changeset(attrs)
        |> Repo.update()
    end
  end

  defp list_daily_logs_map(employee_id, start_date, end_date) do
    from(l in DailyLog,
      where: l.employee_id == ^employee_id,
      where: l.date >= ^start_date and l.date <= ^end_date
    )
    |> Repo.all()
    |> Map.new(fn log -> {log.date, log} end)
  end
end
