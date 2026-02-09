defmodule PontodigitalWeb.AdminLive.WorkScheduleManagement.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Company.WorkSchedule

  import PontodigitalWeb.AdminLive.WorkScheduleManagement.WorkScheduleComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :work_schedules, Company.list_work_schedules())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Jornada")
    |> assign(:work_schedule, Company.get_work_schedule!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nova Jornada")
    |> assign(:work_schedule, %WorkSchedule{work_days: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Jornadas de Trabalho")
    |> assign(:work_schedule, nil)
  end

  @impl true
  def handle_info({PontodigitalWeb.AdminLive.WorkScheduleManagement.FormComponent, {:saved, work_schedule}}, socket) do
    {:noreply, stream_insert(socket, :work_schedules, work_schedule)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    work_schedule = Company.get_work_schedule!(id)
    {:ok, _} = Company.delete_work_schedule(work_schedule)

    {:noreply, stream_delete(socket, :work_schedules, work_schedule)}
  end
end
