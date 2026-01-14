defmodule PontodigitalWeb.AdminLive.HolidayManagement.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Timekeeping
  alias Pontodigital.Timekeeping.Holiday

  import PontodigitalWeb.AdminLive.HolidayManagement.HolidayComponents

  @impl true
  def mount(_params, _session, socket) do
    holidays = Timekeeping.list_all_holidays()

    changeset = Timekeeping.change_holiday(%Holiday{})

    {:ok,
     socket
     |> assign(:holidays, holidays)
     |> assign(:form, to_form(changeset))
     |> assign(:page_title, "Gestão de Feriados")}
  end

  @impl true
  def handle_event("validate", %{"holiday" => params}, socket) do
    changeset =
      %Holiday{}
      |> Timekeeping.change_holiday(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"holiday" => params}, socket) do
    case Timekeeping.create_holiday(params) do
      {:ok, holiday} ->
        new_list = socket.assign.holidays ++ [holiday]

        sorted_list = Enum.sort_by(new_list, & &1.date, Date)

        changeset = Timekeeping.change_holiday(%Holiday{})

        {:noreply,
         socket
         |> put_flash(:info, "Feriado criado com sucesso.")
         |> assign(:holidays, sorted_list)
         |> assign(:form, to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    holiday = Timekeeping.get_holiday!(id)
    {:ok, _} = Timekeeping.delete_holiday(holiday)

    new_list = Enum.reject(socket.assign.holidays, fn h -> h.id == holiday.id end)

    {:noreply,
     socket
     |> put_flash(:info, "Feriado removido.")
     |> assign(:holidays, new_list)}
  end
end
