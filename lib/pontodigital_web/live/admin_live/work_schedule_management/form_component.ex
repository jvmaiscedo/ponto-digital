defmodule PontodigitalWeb.AdminLive.WorkScheduleManagement.FormComponent do
  use PontodigitalWeb, :live_component

  alias Pontodigital.Company

  @impl true
  def update(%{work_schedule: work_schedule} = assigns, socket) do
    changeset = Company.change_work_schedule(work_schedule)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"work_schedule" => params}, socket) do
    changeset =
      socket.assigns.work_schedule
      |> Company.change_work_schedule(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"work_schedule" => params}, socket) do
    save_work_schedule(socket, socket.assigns.action, params)
  end

  defp save_work_schedule(socket, :edit, params) do
    case Company.update_work_schedule(socket.assigns.work_schedule, params) do
      {:ok, work_schedule} ->
        notify_parent({:saved, work_schedule})

        {:noreply,
         socket
         |> put_flash(:info, "Jornada atualizada com sucesso")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_work_schedule(socket, :new, params) do
    case Company.create_work_schedule(params) do
      {:ok, work_schedule} ->
        notify_parent({:saved, work_schedule})

        {:noreply,
         socket
         |> put_flash(:info, "Jornada criada com sucesso")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
