defmodule Ledger.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Ledger.Repo

      import Ecto
      import Ecto.Query
      import Ledger.RepoCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Ledger.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
