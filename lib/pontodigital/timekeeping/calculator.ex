defmodule Pontodigital.Timekeeping.Calculator do
  @moduledoc """
  Modulo responsavel pelas regras de negocio de calculo de horas,
  saldos e interpretacao de ausencias/faltas
  """

  alias Pontodigital.Timekeeping.{Absence, Vacation}

  @doc """
  Calcula o saldo de um dia específico baseado em todas as variáveis (Pontos, Meta, Abonos, Feriados).
  Retorna: {saldo_minutos, status_formatado, trabalhado_minutos}
  """
  def calculate_daily_balance(pontos, meta_diaria, abono, feriado_nome, vacation) do
    do_calculate(pontos, meta_diaria, abono, feriado_nome, vacation)
  end

  @doc """
  Calcula os minutos trabalhados brutos (sem descontar meta).
  """
  def calculate_worked_minutes(%{entrada: ent, saida: sai} = pontos)
      when not is_nil(ent) and not is_nil(sai) do
    entrada_time = ent.original.timestamp
    saida_time = sai.original.timestamp
    almoco = calculate_lunch_break(pontos)

    diff_seconds = DateTime.diff(saida_time, entrada_time, :second)
    {:ok, div(diff_seconds, 60) - almoco}
  end

  def calculate_worked_minutes(_), do: :error

  @doc """
  Formata minutos em string "+HH:MM" ou "-HH:MM".
  """
  def format_balance(minutos) do
    horas = div(abs(minutos), 60)
    mins = rem(abs(minutos), 60)
    sinal = if minutos < 0, do: "-", else: "+"

    "#{sinal}#{String.pad_leading(Integer.to_string(horas), 2, "0")}:#{String.pad_leading(Integer.to_string(mins), 2, "0")}"
  end

  # funcoes privadas
  defp do_calculate(_points, _meta, _abono, _feriado, %Vacation{}) do
    {0, "FÉRIAS", 0}
  end

  defp do_calculate(_pontos, _meta, _abono, feriado_nome, nil) when not is_nil(feriado_nome) do
    {0, "FERIADO", 0}
  end

  defp do_calculate(_pontos, _meta, %Absence{}, _feriado_nome, nil) do
    {0, "ABONADO", 0}
  end

  defp do_calculate(pontos, meta, nil, nil, nil) do
    case calculate_worked_minutes(pontos) do
      {:ok, trabalhados} ->
        saldo = trabalhados - meta
        {saldo, format_balance(saldo), trabalhados}

      :error ->
        {:missing_records, -meta, 0}
    end
  end

  defp calculate_lunch_break(pontos) do
    with ida when not is_nil(ida) <- pontos[:ida_almoco],
         retorno when not is_nil(retorno) <- pontos[:retorno_almoco] do
      ida_time = ida.original.timestamp
      retorno_time = retorno.original.timestamp

      diff_seconds = DateTime.diff(retorno_time, ida_time, :second)
      div(diff_seconds, 60)
    else
      _ -> 0
    end
  end
end
