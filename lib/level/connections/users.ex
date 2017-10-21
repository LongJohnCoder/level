defmodule Level.Connections.Users do
  @moduledoc """
  Functions for querying users.
  """

  alias Level.Spaces.User
  import Ecto.Query

  @default_args %{
    first: 10,
    before: nil,
    after: nil,
    order_by: %{
      field: :username,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for users belonging to a given space.
  """
  def get(space, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from u in User,
          where: u.space_id == ^space.id and u.state == "ACTIVE"

        Level.Pagination.fetch_result(Level.Repo, base_query, args)
      error ->
        error
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end