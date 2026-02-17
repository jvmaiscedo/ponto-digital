defmodule Pontodigital.Communication do
  import Ecto.Query, warn: false
  alias Pontodigital.Repo

  alias Pontodigital.Communication.InboxMessage

  @moduledoc """
  Contexto de Comunicação interna (Mensageria).

  Gerencia o envio e leitura de `InboxMessages`. Implementa filtros de visibilidade baseados na hierarquia da empresa.
  """

  @doc """
  Lista mensagens com filtragem dinâmica baseada no papel (`role`) do usuário atual.

  ## Regras de Visibilidade
  - **Master:** Visualiza todas as mensagens do sistema.
  - **Admin (Gestor):** Visualiza apenas as mensagens enviadas por funcionários do **seu departamento** (`department.manager_id == current_user.id`).
  - **Outros:** Retorna uma lista vazia (query com `is_nil(id)`), impedindo acesso a dados não autorizados.

  ## Parâmetros
  - `params`: Parâmetros de paginação e filtro do `Flop`.
  - `current_employee`: O funcionário logado que está requisitando os dados.

  ## Retorno
  - `{:ok, {list_messages, meta}}`: Tupla padrão do Flop com resultados e metadados.
  - `{:error, meta}`: Erro na validação dos parâmetros de filtro.
  """
  def list_inbox_messages(params \\ %{}, current_employee) do
    current_employee = Pontodigital.Repo.preload(current_employee, :user)

    base_query =
      InboxMessage
      |> preload(employee: :department)

    query =
      cond do
        current_employee.user.role == :master ->
          base_query

        current_employee.user.role == :admin ->
          base_query
          |> join(:inner, [m], e in assoc(m, :employee))
          |> join(:inner, [m, e], d in assoc(e, :department))
          |> where([m, e, d], d.manager_id == ^current_employee.id)

        true ->
          base_query |> where([m], is_nil(m.id))
      end

    Flop.validate_and_run(query, params, for: InboxMessage)
  end

  @doc """
  Busca uma mensagem específica pelo ID.
  Precarrega automaticamente o funcionário remetente e seu departamento.

  ## Parâmetros
  - `id`: ID da mensagem.

  ## Retorno
  - `%InboxMessage{}`: Mensagem encontrada.
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrar.
  """
  def get_inbox_message!(id) do
    InboxMessage
    |> Repo.get!(id)
    |> Repo.preload(:employee)
  end

  @doc """
  Cria uma nova mensagem na caixa de entrada.
  Geralmente utilizada por componentes de "Fale Conosco" ou "Reportar Erro" dos funcionários.

  ## Parâmetros
  - `attrs`: Mapa de atributos (ex: `title`, `body`, `employee_id`).

  ## Retorno
  - `{:ok, %InboxMessage{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def create_inbox_message(attrs \\ %{}) do
    %InboxMessage{}
    |> InboxMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atualiza uma mensagem existente.
  Utilizado para marcar mensagens como lidas (`read_at`), arquivadas ou responder administrativamente.

  ## Parâmetros
  - `inbox_message`: Struct da mensagem original.
  - `attrs`: Atributos a serem atualizados.

  ## Retorno
  - `{:ok, %InboxMessage{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def update_inbox_message(%InboxMessage{} = inbox_message, attrs) do
    inbox_message
    |> InboxMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Remove uma mensagem do sistema.

  ## Parâmetros
  - `inbox_message`: Struct da mensagem a ser excluída.

  ## Retorno
  - `{:ok, %InboxMessage{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Falha.
  """
  def delete_inbox_message(%InboxMessage{} = inbox_message) do
    Repo.delete(inbox_message)
  end

  @doc """
  Gera um changeset para rastreamento de mudanças em mensagens.
  Utilizado em formulários.

  ## Retorno
  - `%Ecto.Changeset{}`
  """
  def change_inbox_message(%InboxMessage{} = inbox_message, attrs \\ %{}) do
    InboxMessage.changeset(inbox_message, attrs)
  end

  @doc """
  Marca uma mensagem como lida, definindo o carimbo de data/hora atual.
  Trunca o horário para segundos para garantir consistência entre banco e aplicação.

  ## Parâmetros
  - `message`: A struct `%InboxMessage{}` a ser marcada.

  ## Retorno
  - `{:ok, %InboxMessage{}}`: Sucesso (campo `read_at` atualizado).
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def mark_as_read(%InboxMessage{} = message) do
    now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    message
    |> Ecto.Changeset.change(read_at: now)
    |> Repo.update()
  end
end
