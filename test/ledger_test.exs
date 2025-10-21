defmodule LedgerTest do
  use ExUnit.Case, async: true

  alias Ledger.Repo
  alias Ledger.Usuarios.FuncionesUsuario
  alias Ledger.Usuarios.UsuarioSchema
  alias Ledger.Monedas.FuncionesMoneda
  alias Ledger.Monedas.MonedaSchema
  alias Ledger.Transacciones.FuncionesTransaccion
  alias Ledger.Transacciones.TransaccionSchema
  alias Ledger.Handler
  alias Ledger.Parser.Parser
  alias Ledger.Parser.{Helpers, Usuarios, Monedas, Transacciones}

  import ExUnit.CaptureIO

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    :ok
  end

  describe "Parser.Helpers" do
    test "parse_flags válido" do
      flags = ["-n=Juan", "-b=01-01-1990"]
      mapping = %{"-n" => :nombre, "-b" => :fecha_nacimiento}

      assert {:ok, %{nombre: "Juan", fecha_nacimiento: "01-01-1990"}} =
               Helpers.parse_flags(flags, mapping)
    end

    test "parse_flags con flag desconocido" do
      flags = ["-x=valor"]
      mapping = %{"-n" => :nombre}

      assert {:error, {:unknown_flag, "-x=valor"}} = Helpers.parse_flags(flags, mapping)
    end

    test "parse_flags con formato inválido" do
      flags = ["invalido"]
      mapping = %{"-n" => :nombre}

      assert {:error, {:unknown_flag, "invalido"}} = Helpers.parse_flags(flags, mapping)
    end

    test "parse_verificacion con todos los campos" do
      required = [:nombre, :fecha_nacimiento]
      map = %{nombre: "Juan", fecha_nacimiento: "01-01-1990"}

      assert {:ok, ^map} = Helpers.parse_verificacion(required, map)
    end

    test "parse_verificacion con campos faltantes" do
      required = [:nombre, :fecha_nacimiento]
      map = %{nombre: "Juan"}

      assert {:error, {:missing_flags, [:fecha_nacimiento]}} =
               Helpers.parse_verificacion(required, map)
    end

    test "parse_float válido" do
      assert {:ok, 10.5} = Helpers.parse_float("10.5")
    end

    test "parse_float inválido" do
      assert {:error, :invalid_float} = Helpers.parse_float("abc")
      assert {:error, :invalid_float} = Helpers.parse_float(nil)
    end

    test "parse_integer válido" do
      assert {:ok, 42} = Helpers.parse_integer("42")
    end

    test "parse_integer inválido" do
      assert {:error, :invalid_integer} = Helpers.parse_integer("abc")
      assert {:error, :invalid_integer} = Helpers.parse_integer(nil)
    end

    test "parse_precio válido" do
      assert {:ok, 1.5} = Helpers.parse_precio("1.5")
    end

    test "parse_precio inválido" do
      assert {:error, :precio_invalid} = Helpers.parse_precio("xyz")
      assert {:error, :precio_invalid} = Helpers.parse_precio(nil)
    end
  end

  describe "Parser.Usuarios" do
    test "parse_crear válido" do
      flags = ["-n=Juan", "-b=01-01-1990"]

      assert {:ok, %{nombre: "Juan", fecha_nacimiento: "01-01-1990"}} =
               Usuarios.parse_crear(flags)
    end

    test "parse_crear sin nombre" do
      flags = ["-b=01-01-1990"]

      assert {:error, {:missing_flags, [:nombre]}} = Usuarios.parse_crear(flags)
    end

    test "parse_editar válido" do
      flags = ["-id=1", "-n=NuevoNombre"]

      assert {:ok, %{id: "1", nuevo_nombre: "NuevoNombre"}} = Usuarios.parse_editar(flags)
    end

    test "parse_editar sin nuevo_nombre" do
      flags = ["-id=1"]

      assert {:error, {:missing_flags, [:nuevo_nombre]}} = Usuarios.parse_editar(flags)
    end

    test "parse_id válido" do
      flags = ["-id=42"]

      assert {:ok, %{id: "42"}} = Usuarios.parse_id(flags)
    end

    test "parse_id sin id" do
      flags = []

      assert {:error, {:missing_flags, [:id]}} = Usuarios.parse_id(flags)
    end
  end

  describe "Parser.Monedas" do
    test "parse_crear válido" do
      flags = ["-n=USD", "-p=1.0"]

      assert {:ok, %{nombre: "USD", precio_usd: 1.0}} = Monedas.parse_crear(flags)
    end

    test "parse_crear con precio inválido" do
      flags = ["-n=USD", "-p=abc"]

      assert {:error, :precio_invalid} = Monedas.parse_crear(flags)
    end

    test "parse_crear sin campos requeridos" do
      flags = ["-n=USD"]

      assert {:error, {:missing_flags, [:precio_usd]}} = Monedas.parse_crear(flags)
    end

    test "parse_editar válido" do
      flags = ["-id=1", "-p=2.5"]

      assert {:ok, %{id: "1", precio_usd: 2.5}} = Monedas.parse_editar(flags)
    end

    test "parse_editar con precio inválido" do
      flags = ["-id=1", "-p=xyz"]

      assert {:error, :precio_invalid} = Monedas.parse_editar(flags)
    end

    test "parse_id válido" do
      flags = ["-id=5"]

      assert {:ok, %{id: "5"}} = Monedas.parse_id(flags)
    end
  end

  describe "Parser.Transacciones" do
    test "parse_alta_cuenta válido" do
      flags = ["-u=1", "-m=2", "-a=100.0"]

      assert {:ok, %{usuario_destino_id: "1", moneda_destino_id: "2", monto: 100.0}} =
               Transacciones.parse_alta_cuenta(flags)
    end

    test "parse_alta_cuenta con monto inválido" do
      flags = ["-u=1", "-m=2", "-a=abc"]

      assert {:error, :invalid_float} = Transacciones.parse_alta_cuenta(flags)
    end

    test "parse_alta_cuenta sin campos requeridos" do
      flags = ["-u=1", "-m=2"]

      assert {:error, {:missing_flags, [:monto]}} = Transacciones.parse_alta_cuenta(flags)
    end

    test "parse_transferencia válido" do
      flags = ["-o=1", "-d=2", "-m=3", "-a=50.0"]

      assert {:ok,
              %{
                usuario_origen_id: 1,
                usuario_destino_id: 2,
                moneda_destino_id: 3,
                moneda_origen_id: 3,
                monto: 50.0
              }} = Transacciones.parse_transferencia(flags)
    end

    test "parse_transferencia con usuario origen inválido" do
      flags = ["-o=abc", "-d=2", "-m=3", "-a=50.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_transferencia(flags)
    end

    test "parse_transferencia con usuario destino inválido" do
      flags = ["-o=1", "-d=xyz", "-m=3", "-a=50.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_transferencia(flags)
    end

    test "parse_transferencia con moneda inválida" do
      flags = ["-o=1", "-d=2", "-m=abc", "-a=50.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_transferencia(flags)
    end

    test "parse_transferencia sin campos requeridos" do
      flags = ["-o=1", "-d=2", "-m=3"]

      assert {:error, {:missing_flags, [:monto]}} = Transacciones.parse_transferencia(flags)
    end

    test "parse_swap válido" do
      flags = ["-u=1", "-mo=2", "-md=3", "-a=25.0"]

      assert {:ok,
              %{
                usuario_origen_id: 1,
                moneda_origen_id: 2,
                moneda_destino_id: 3,
                monto: 25.0
              }} = Transacciones.parse_swap(flags)
    end

    test "parse_swap con usuario inválido" do
      flags = ["-u=abc", "-mo=2", "-md=3", "-a=25.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_swap(flags)
    end

    test "parse_swap con moneda origen inválida" do
      flags = ["-u=1", "-mo=abc", "-md=3", "-a=25.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_swap(flags)
    end

    test "parse_swap con moneda destino inválida" do
      flags = ["-u=1", "-mo=2", "-md=xyz", "-a=25.0"]

      assert {:error, :invalid_integer} = Transacciones.parse_swap(flags)
    end

    test "parse_swap con monto inválido" do
      flags = ["-u=1", "-mo=2", "-md=3", "-a=invalid"]

      assert {:error, :invalid_float} = Transacciones.parse_swap(flags)
    end

    test "parse_id válido" do
      flags = ["-id=10"]

      assert {:ok, %{id: 10}} = Transacciones.parse_id(flags)
    end

    test "parse_id con id inválido" do
      flags = ["-id=abc"]

      assert {:error, :invalid_integer} = Transacciones.parse_id(flags)
    end

    test "parse_balance válido" do
      flags = ["-c1=1"]

      assert {:ok, %{usuario_id: 1}} = Transacciones.parse_balance(flags)
    end

    test "parse_balance con moneda" do
      flags = ["-c1=1", "-m=USD"]

      assert {:ok, %{usuario_id: 1, moneda_id: "USD"}} = Transacciones.parse_balance(flags)
    end

    test "parse_balance con usuario inválido" do
      flags = ["-c1=abc"]

      assert {:error, :invalid_integer} = Transacciones.parse_balance(flags)
    end

    test "parse_balance sin usuario" do
      flags = []

      assert {:error, {:missing_flags, [:usuario_id]}} = Transacciones.parse_balance(flags)
    end
  end

  describe "Parser.Parser" do
    test "parser_args crear_usuario" do
      args = ["crear_usuario", "-n=Juan", "-b=01-01-1990"]

      assert {:crear_usuario, {:ok, %{nombre: "Juan", fecha_nacimiento: "01-01-1990"}}} =
               Parser.parser_args(args)
    end

    test "parser_args editar_usuario" do
      args = ["editar_usuario", "-id=1", "-n=NuevoNombre"]

      assert {:editar_usuario, {:ok, %{id: "1", nuevo_nombre: "NuevoNombre"}}} =
               Parser.parser_args(args)
    end

    test "parser_args ver_usuario" do
      args = ["ver_usuario", "-id=1"]

      assert {:ver_usuario, {:ok, %{id: "1"}}} = Parser.parser_args(args)
    end

    test "parser_args borrar_usuario" do
      args = ["borrar_usuario", "-id=1"]

      assert {:borrar_usuario, {:ok, %{id: "1"}}} = Parser.parser_args(args)
    end

    test "parser_args crear_moneda" do
      args = ["crear_moneda", "-n=USD", "-p=1.0"]

      assert {:crear_moneda, {:ok, %{nombre: "USD", precio_usd: 1.0}}} =
               Parser.parser_args(args)
    end

    test "parser_args editar_moneda" do
      args = ["editar_moneda", "-id=1", "-p=2.0"]

      assert {:editar_moneda, {:ok, %{id: "1", precio_usd: 2.0}}} = Parser.parser_args(args)
    end

    test "parser_args ver_moneda" do
      args = ["ver_moneda", "-id=1"]

      assert {:ver_moneda, {:ok, %{id: "1"}}} = Parser.parser_args(args)
    end

    test "parser_args borrar_moneda" do
      args = ["borrar_moneda", "-id=1"]

      assert {:borrar_moneda, {:ok, %{id: "1"}}} = Parser.parser_args(args)
    end

    test "parser_args alta_cuenta" do
      args = ["alta_cuenta", "-u=1", "-m=2", "-a=100.0"]

      assert {:alta_cuenta,
              {:ok, %{usuario_destino_id: "1", moneda_destino_id: "2", monto: 100.0}}} =
               Parser.parser_args(args)
    end

    test "parser_args realizar_transferencia" do
      args = ["realizar_transferencia", "-o=1", "-d=2", "-m=3", "-a=50.0"]

      assert {:realizar_transferencia, {:ok, _}} = Parser.parser_args(args)
    end

    test "parser_args realizar_swap" do
      args = ["realizar_swap", "-u=1", "-mo=2", "-md=3", "-a=25.0"]

      assert {:realizar_swap, {:ok, _}} = Parser.parser_args(args)
    end

    test "parser_args deshacer_transaccion" do
      args = ["deshacer_transaccion", "-id=1"]

      assert {:deshacer_transaccion, {:ok, %{id: 1}}} = Parser.parser_args(args)
    end

    test "parser_args ver_transaccion" do
      args = ["ver_transaccion", "-id=1"]

      assert {:ver_transaccion, {:ok, %{id: 1}}} = Parser.parser_args(args)
    end

    test "parser_args balance" do
      args = ["balance", "-c1=1"]

      assert {:balance, {:ok, %{usuario_id: 1}}} = Parser.parser_args(args)
    end

    test "parser_args comando inválido" do
      args = ["comando_invalido"]

      assert {:error, :invalid_subcommand} = Parser.parser_args(args)
    end

    test "parser_args con error de parsing" do
      args = ["crear_usuario", "-n=Juan"]

      assert {:error, {:missing_flags, [:fecha_nacimiento]}} = Parser.parser_args(args)
    end
  end

  describe "Handler" do
    setup do
      usuario =
        %UsuarioSchema{
          nombre: "Handler#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      %{usuario: usuario, moneda: moneda}
    end

    test "handle crear_usuario" do
      nombre = "Test#{System.unique_integer([:positive])}"
      params = {:ok, %{nombre: nombre, fecha_nacimiento: "01-01-1990"}}

      assert :ok = Handler.handle({:crear_usuario, params})
    end

    test "handle editar_usuario", %{usuario: u} do
      params = {:ok, %{id: u.id, nuevo_nombre: "Editado"}}

      assert :ok = Handler.handle({:editar_usuario, params})
    end

    test "handle ver_usuario", %{usuario: u} do
      params = {:ok, %{id: u.id}}

      assert :ok = Handler.handle({:ver_usuario, params})
    end

    test "handle borrar_usuario" do
      user =
        %UsuarioSchema{
          nombre: "Borrar#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      params = {:ok, %{id: user.id}}

      assert :ok = Handler.handle({:borrar_usuario, params})
    end

    test "handle crear_moneda" do
      params = {:ok, %{nombre: "EUR", precio_usd: 1.2}}

      assert :ok = Handler.handle({:crear_moneda, params})
    end

    test "handle editar_moneda", %{moneda: m} do
      params = {:ok, %{id: m.id, precio_usd: 2.0}}

      assert :ok = Handler.handle({:editar_moneda, params})
    end

    test "handle ver_moneda", %{moneda: m} do
      params = {:ok, %{id: m.id}}

      assert :ok = Handler.handle({:ver_moneda, params})
    end

    test "handle borrar_moneda", %{moneda: m} do
      params = {:ok, %{id: m.id}}

      assert :ok = Handler.handle({:borrar_moneda, params})
    end

    test "handle alta_cuenta", %{usuario: u, moneda: m} do
      params = {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m.id, monto: 100.0}}

      assert {:ok, _} = Handler.handle({:alta_cuenta, params})
    end

    test "handle realizar_transferencia", %{usuario: u, moneda: m} do
      u2 =
        %UsuarioSchema{
          nombre: "U2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      Handler.handle(
        {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m.id, monto: 100}}}
      )

      Handler.handle(
        {:alta_cuenta, {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: m.id, monto: 50}}}
      )

      params =
        {:ok,
         %{usuario_origen_id: u.id, usuario_destino_id: u2.id, moneda_destino_id: m.id, monto: 50}}

      assert {:ok, _} = Handler.handle({:realizar_transferencia, params})
    end

    test "handle realizar_swap", %{usuario: u} do
      m1 =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      Handler.handle(
        {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m1.id, monto: 100}}}
      )

      Handler.handle(
        {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m2.id, monto: 100}}}
      )

      params =
        {:ok,
         %{usuario_origen_id: u.id, moneda_origen_id: m1.id, moneda_destino_id: m2.id, monto: 10}}

      assert {:ok, _} = Handler.handle({:realizar_swap, params})
    end

    test "handle ver_transaccion", %{usuario: u, moneda: m} do
      {:ok, t} =
        Handler.handle(
          {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m.id, monto: 100}}}
        )

      params = {:ok, %{id: t.id}}

      assert {:ok, _} = Handler.handle({:ver_transaccion, params})
    end

    test "handle deshacer_transaccion", %{usuario: u, moneda: m} do
      {:ok, t} =
        Handler.handle(
          {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m.id, monto: 100}}}
        )

      params = {:ok, %{id: t.id}}

      assert {:ok, _} = Handler.handle({:deshacer_transaccion, params})
    end

    test "handle balance", %{usuario: u, moneda: m} do
      Handler.handle(
        {:alta_cuenta, {:ok, %{usuario_destino_id: u.id, moneda_destino_id: m.id, monto: 100}}}
      )

      params = {:ok, %{usuario_id: u.id}}

      assert {:ok, _} = Handler.handle({:balance, params})
    end

    test "handle comando desconocido" do
      assert {:error, {:unknown_command, :comando_falso}} =
               Handler.handle({:comando_falso, {:ok, %{}}})
    end
  end

  describe "Ledger.main" do
    test "main con crear_usuario" do
      nombre = "Main#{System.unique_integer([:positive])}"
      args = ["crear_usuario", "-n=#{nombre}", "-b=01-01-1990"]

      capture_io(fn ->
        assert :ok = Ledger.main(args)
      end)
    end

    test "main con ver_usuario" do
      user =
        %UsuarioSchema{
          nombre: "Main#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      args = ["ver_usuario", "-id=#{user.id}"]

      capture_io(fn ->
        assert :ok = Ledger.main(args)
      end)
    end

    test "main con crear_moneda" do
      args = ["crear_moneda", "-n=CHF", "-p=1.1"]

      capture_io(fn ->
        assert :ok = Ledger.main(args)
      end)
    end

    test "main con alta_cuenta" do
      user =
        %UsuarioSchema{
          nombre: "Main#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      args = ["alta_cuenta", "-u=#{user.id}", "-m=#{moneda.id}", "-a=100.0"]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con balance" do
      user =
        %UsuarioSchema{
          nombre: "Main#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      capture_io(fn ->
        Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{moneda.id}", "-a=100.0"])
      end)

      args = ["balance", "-c1=#{user.id}"]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con comando inválido" do
      args = ["comando_invalido"]

      output =
        capture_io(fn ->
          Ledger.main(args)
        end)

      assert output =~ "error"
    end

    test "main con error de parsing" do
      args = ["crear_usuario", "-n=Test"]

      output =
        capture_io(fn ->
          Ledger.main(args)
        end)

      assert output =~ "error"
    end
  end

  describe "Output" do
    test "output de usuario" do
      user =
        %UsuarioSchema{
          nombre: "Output#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:usuario, user})
        end)

      assert output =~ "Usuario ID:"
      assert output =~ user.nombre
    end

    test "output de moneda" do
      moneda =
        %MonedaSchema{nombre: "OUT#{System.unique_integer([:positive])}", precio_usd: 1.5}
        |> Repo.insert!()

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:moneda, moneda})
        end)

      assert output =~ "Moneda ID:"
      assert output =~ moneda.nombre
    end

    test "output de balance" do
      user =
        %UsuarioSchema{
          nombre: "Balance#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "BAL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      balances = [%{moneda_id: moneda.id, total: 100.0}]

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:balance, :sin_moneda, balances})
        end)

      assert output =~ "Balance:"
    end

    test "output de transacción ALTA_CUENTA" do
      user =
        %UsuarioSchema{
          nombre: "Trans#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "TRX#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:transaccion, t})
        end)

      assert output =~ "ALTA_CUENTA"
      assert output =~ "100.0"
    end

    test "output de transacción TRANSFERENCIA" do
      u1 =
        %UsuarioSchema{
          nombre: "U1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "U2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "TRF#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_transferencia(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             usuario_destino_id: u2.id,
             moneda_destino_id: moneda.id,
             monto: 50
           }}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:transaccion, t})
        end)

      assert output =~ "TRANSFERENCIA"
    end

    test "output de transacción SWAP" do
      user =
        %UsuarioSchema{
          nombre: "Swap#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      m1 =
        %MonedaSchema{nombre: "SWP#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "SW2#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: m1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: m2.id, monto: 100}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_swap(
          {:ok,
           %{
             usuario_origen_id: user.id,
             moneda_origen_id: m1.id,
             moneda_destino_id: m2.id,
             monto: 10
           }}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:transaccion, t})
        end)

      assert output =~ "SWAP"
    end
  end

  describe "Usuarios" do
    test "crear usuario válido" do
      nombre = "Juan#{System.unique_integer([:positive])}"
      attrs = %{nombre: nombre, fecha_nacimiento: "01-01-2000"}
      assert :ok = FuncionesUsuario.crear_usuario({:ok, attrs})
    end

    test "rechaza usuario menor de edad" do
      today = Date.utc_today()
      minor_date = "#{today.day}-#{today.month}-#{today.year - 10}"

      attrs = %{
        nombre: "Joven#{System.unique_integer([:positive])}",
        fecha_nacimiento: minor_date
      }

      assert {:error, [crear_usuario: "El usuario debe ser mayor de 18 años."]} =
               FuncionesUsuario.crear_usuario({:ok, attrs})
    end

    test "editar nombre de usuario" do
      user =
        %UsuarioSchema{
          nombre: "Ana#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      attrs = %{id: user.id, nuevo_nombre: "AnaNueva"}
      assert :ok = FuncionesUsuario.editar_usuario({:ok, attrs})
    end

    test "no permite nombre igual" do
      user =
        %UsuarioSchema{
          nombre: "Pedro#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      attrs = %{id: user.id, nuevo_nombre: user.nombre}

      assert {:error, [editar_usuario: "El nuevo nombre no puede ser igual al actual."]} =
               FuncionesUsuario.editar_usuario({:ok, attrs})
    end

    test "ver usuario válido" do
      user =
        %UsuarioSchema{
          nombre: "Ver#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      assert :ok = FuncionesUsuario.ver_usuario({:ok, %{id: user.id}})
    end

    test "ver usuario inexistente" do
      assert {:error, [ver_usuario: "No se encontró el usuario."]} =
               FuncionesUsuario.ver_usuario({:ok, %{id: -1}})
    end

    test "editar usuario inexistente" do
      assert {:error, [editar_usuario: "No se encontró el usuario."]} =
               FuncionesUsuario.editar_usuario({:ok, %{id: -1, nuevo_nombre: "Nuevo"}})
    end
  end

  describe "Monedas" do
    test "crear moneda válida" do
      attrs = %{nombre: "USD", precio_usd: 1.0}
      assert :ok = FuncionesMoneda.crear_moneda({:ok, attrs})
    end

    test "rechaza moneda con nombre corto" do
      attrs = %{nombre: "US", precio_usd: 1.0}

      assert {:error, [crear_moneda: "El nombre de la moneda debe tener al menos 3 letras."]} =
               FuncionesMoneda.crear_moneda({:ok, attrs})
    end

    test "rechaza moneda con nombre largo" do
      attrs = %{nombre: "USDDDD", precio_usd: 1.0}

      assert {:error, [crear_moneda: "El nombre de la moneda no puede tener más de 4 letras."]} =
               FuncionesMoneda.crear_moneda({:ok, attrs})
    end

    test "rechaza moneda con precio inválido" do
      attrs = %{nombre: "ARS", precio_usd: -3.0}

      assert {:error, [crear_moneda: "El precio de la moneda debe ser un número positivo."]} =
               FuncionesMoneda.crear_moneda({:ok, attrs})
    end

    test "editar precio de moneda" do
      moneda =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      attrs = %{id: moneda.id, precio_usd: 2.0}
      assert :ok = FuncionesMoneda.editar_moneda({:ok, attrs})
    end

    test "ver moneda válida" do
      moneda =
        %MonedaSchema{nombre: "BTC#{System.unique_integer([:positive])}", precio_usd: 20000.0}
        |> Repo.insert!()

      assert :ok = FuncionesMoneda.ver_moneda({:ok, %{id: moneda.id}})
    end

    test "rechaza moneda duplicada" do
      nombre = "DUP#{System.unique_integer([:positive])}"
      attrs = %{nombre: nombre, precio_usd: 1.0}
      FuncionesMoneda.crear_moneda({:ok, attrs})

      assert {:error, [crear_moneda: "El nombre de la moneda debe estar en mayúsculas."]} =
               FuncionesMoneda.crear_moneda({:ok, attrs})
    end
  end

  describe "Transacciones" do
    setup do
      usuario1 =
        %UsuarioSchema{
          nombre: "Alice#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      usuario2 =
        %UsuarioSchema{
          nombre: "Bob#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1985-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      %{u1: usuario1, u2: usuario2, moneda: moneda}
    end

    test "alta de cuenta válida", %{u1: u1, moneda: moneda} do
      attrs = %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100.0}

      assert {:ok, %TransaccionSchema{monto: 100.0}} =
               FuncionesTransaccion.alta_cuenta({:ok, attrs})
    end

    test "alta de cuenta con usuario inexistente", %{moneda: moneda} do
      attrs = %{usuario_destino_id: -1, moneda_destino_id: moneda.id, monto: 100.0}

      assert {:error, :user_not_found} =
               FuncionesTransaccion.alta_cuenta({:ok, attrs})
    end

    test "alta de cuenta con moneda inexistente", %{u1: u1} do
      attrs = %{usuario_destino_id: u1.id, moneda_destino_id: -1, monto: 100.0}

      assert {:error, :moneda_not_found} =
               FuncionesTransaccion.alta_cuenta({:ok, attrs})
    end

    test "alta de cuenta con monto negativo", %{u1: u1, moneda: moneda} do
      attrs = %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: -50.0}

      assert {:error, :invalid_amount} =
               FuncionesTransaccion.alta_cuenta({:ok, attrs})
    end

    test "transferencia válida", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: 50
      }

      assert {:ok, %TransaccionSchema{monto: 50.0}} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "rechaza transferencia sin saldo", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 10}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 1}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: 50
      }

      assert {:error, :insufficient_funds} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "swap válido entre monedas" do
      usuario =
        %UsuarioSchema{
          nombre: "Carlos#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda1 =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      moneda2 =
        %MonedaSchema{nombre: "ARS#{System.unique_integer([:positive])}", precio_usd: 0.001}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: usuario.id, moneda_destino_id: moneda1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: usuario.id, moneda_destino_id: moneda2.id, monto: 5000}}
      )

      attrs = %{
        usuario_origen_id: usuario.id,
        moneda_origen_id: moneda1.id,
        moneda_destino_id: moneda2.id,
        monto: 10
      }

      assert {:ok, %TransaccionSchema{monto: 10.0}} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "reversión de última transacción", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 200}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_transferencia(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             usuario_destino_id: u2.id,
             moneda_destino_id: moneda.id,
             monto: 100
           }}
        )

      assert {:ok, _} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})
    end

    test "ver transacción válida", %{u1: u1, moneda: moneda} do
      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      assert {:ok, _} = FuncionesTransaccion.ver_transaccion({:ok, %{id: t.id}})
    end

    test "ver transacción inexistente" do
      assert {:error, :not_found} =
               FuncionesTransaccion.ver_transaccion({:ok, %{id: -1}})
    end

    test "balance con moneda específica", %{u1: u1, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      assert {:ok, _} =
               FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id, moneda_id: moneda.nombre}})
    end

    test "balance usuario inexistente" do
      assert {:error, [balance: "No se encontró el usuario."]} =
               FuncionesTransaccion.balance({:ok, %{usuario_id: -1}})
    end

    test "balance con moneda inexistente", %{u1: u1} do
      assert {:error, [balance: _]} =
               FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id, moneda_id: "NOEXISTE"}})
    end

    test "swap sin fondos suficientes" do
      usuario =
        %UsuarioSchema{
          nombre: "NoFunds#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda1 =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      moneda2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: usuario.id, moneda_destino_id: moneda1.id, monto: 5}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: usuario.id, moneda_destino_id: moneda2.id, monto: 10}}
      )

      attrs = %{
        usuario_origen_id: usuario.id,
        moneda_origen_id: moneda1.id,
        moneda_destino_id: moneda2.id,
        monto: 100
      }

      assert {:error, :insufficient_funds} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "deshacer alta cuenta", %{u1: u1, moneda: moneda} do
      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      assert {:ok, %{tipo: "REVERSION_ALTA_CUENTA"}} =
               FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})
    end

    test "deshacer reversión de alta cuenta", %{u1: u1, moneda: moneda} do
      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      {:ok, rev} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})

      assert {:ok, %{tipo: "ALTA_CUENTA"}} =
               FuncionesTransaccion.deshacer_transaccion({:ok, %{id: rev.id}})
    end

    test "deshacer transacción inexistente" do
      assert {:error, :deshacer, :not_found} =
               FuncionesTransaccion.deshacer_transaccion({:ok, %{id: -1}})
    end
  end

  describe "Usuarios - casos límite y errores" do
    test "no permite crear usuario con nombre duplicado" do
      nombre = "Duplicado#{System.unique_integer([:positive])}"
      attrs = %{nombre: nombre, fecha_nacimiento: "01-01-1990"}
      FuncionesUsuario.crear_usuario({:ok, attrs})

      assert {:error, [crear_usuario: "El nombre de usuario ya se encuentra en uso."]} =
               FuncionesUsuario.crear_usuario({:ok, attrs})
    end

    test "borrar usuario sin transacciones" do
      user =
        %UsuarioSchema{
          nombre: "Eliminar#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      assert :ok = FuncionesUsuario.borrar_usuario({:ok, %{id: user.id}})
    end

    test "no permite borrar usuario con transacciones" do
      user =
        %UsuarioSchema{
          nombre: "ConTransacciones#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      assert {:error, [borrar_usuario: "El usuario tiene transacciones registradas."]} =
               FuncionesUsuario.borrar_usuario({:ok, %{id: user.id}})
    end
  end

  describe "Monedas - casos límite y errores" do
    test "no permite crear moneda con nombre en minúsculas" do
      attrs = %{nombre: "usd", precio_usd: 1.0}

      assert {:error, [crear_moneda: "El nombre de la moneda debe estar en mayúsculas."]} =
               FuncionesMoneda.crear_moneda({:ok, attrs})
    end

    test "editar moneda inexistente" do
      attrs = %{id: -1, precio_usd: 10.0}

      assert {:error, [editar_moneda: "No se encontró la moneda."]} =
               FuncionesMoneda.editar_moneda({:ok, attrs})
    end

    test "ver moneda inexistente" do
      attrs = %{id: -1}

      assert {:error, [ver_moneda: "No se encontró la moneda."]} =
               FuncionesMoneda.ver_moneda({:ok, attrs})
    end

    test "borrar moneda" do
      moneda =
        %MonedaSchema{nombre: "DEL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      assert :ok = FuncionesMoneda.borrar_moneda({:ok, %{id: moneda.id}})
    end

    test "no permite borrar moneda con transacciones" do
      user =
        %UsuarioSchema{
          nombre: "ConMoneda#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "DEL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      assert {:error, [borrar_moneda: "La moneda es parte de una transaccion"]} =
               FuncionesMoneda.borrar_moneda({:ok, %{id: moneda.id}})
    end
  end

  describe "Transacciones - casos límite y errores" do
    setup do
      u1 =
        %UsuarioSchema{
          nombre: "U1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "U2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "BTC#{System.unique_integer([:positive])}", precio_usd: 20000.0}
        |> Repo.insert!()

      %{u1: u1, u2: u2, moneda: moneda}
    end

    test "transferencia con usuario origen sin cuenta activa", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :cuenta_origen_no_existe} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "transferencia con usuario destino sin cuenta activa", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :cuenta_destino_no_existe} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "deshacer transacción que no es la última", %{u1: u1, u2: _u2, moneda: moneda} do
      _user3 =
        %UsuarioSchema{
          nombre: "U3#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      {:ok, t1} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      {:ok, _t2} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 50}}
        )

      assert {:ok, _} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t1.id}})
    end

    test "balance de usuario sin cuentas", %{u1: u1} do
      attrs = %{usuario_id: u1.id}
      assert {:ok, []} = FuncionesTransaccion.balance({:ok, attrs})
    end

    test "swap con usuario inexistente", %{moneda: moneda} do
      attrs = %{
        usuario_origen_id: -1,
        moneda_origen_id: moneda.id,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :user_not_found} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "swap con moneda origen inexistente", %{u1: u1, moneda: moneda} do
      attrs = %{
        usuario_origen_id: u1.id,
        moneda_origen_id: -1,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :moneda_not_found} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "swap con moneda destino inexistente", %{u1: u1, moneda: moneda} do
      attrs = %{
        usuario_origen_id: u1.id,
        moneda_origen_id: moneda.id,
        moneda_destino_id: -1,
        monto: 10
      }

      assert {:error, :moneda_not_found} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "transferencia con usuario origen inexistente", %{u2: u2, moneda: moneda} do
      attrs = %{
        usuario_origen_id: -1,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :user_not_found} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "transferencia con usuario destino inexistente", %{u1: u1, moneda: moneda} do
      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: -1,
        moneda_destino_id: moneda.id,
        monto: 10
      }

      assert {:error, :user_not_found} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "transferencia con moneda inexistente", %{u1: u1, u2: u2} do
      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: -1,
        monto: 10
      }

      assert {:error, :moneda_not_found} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "transferencia con monto negativo", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        usuario_destino_id: u2.id,
        moneda_destino_id: moneda.id,
        monto: -10
      }

      assert {:error, :invalid_amount} =
               FuncionesTransaccion.realizar_transferencia({:ok, attrs})
    end

    test "swap con monto negativo", %{u1: u1, moneda: moneda} do
      moneda2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda2.id, monto: 100}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        moneda_origen_id: moneda.id,
        moneda_destino_id: moneda2.id,
        monto: -10
      }

      assert {:error, :invalid_amount} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end

    test "swap sin cuenta origen", %{u1: u1} do
      moneda1 =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      moneda2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda2.id, monto: 100}}
      )

      attrs = %{
        usuario_origen_id: u1.id,
        moneda_origen_id: moneda1.id,
        moneda_destino_id: moneda2.id,
        monto: 10
      }

      assert {:error, :cuenta_origen_no_existe} =
               FuncionesTransaccion.realizar_swap({:ok, attrs})
    end
  end

  describe "Ledger.main - casos adicionales" do
    test "main con realizar_swap" do
      user =
        %UsuarioSchema{
          nombre: "Swap#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      m1 =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      capture_io(fn ->
        Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{m1.id}", "-a=100.0"])
        Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{m2.id}", "-a=100.0"])
      end)

      args = ["realizar_swap", "-u=#{user.id}", "-mo=#{m1.id}", "-md=#{m2.id}", "-a=10.0"]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con realizar_transferencia" do
      u1 =
        %UsuarioSchema{
          nombre: "Transfer1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "Transfer2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      capture_io(fn ->
        Ledger.main(["alta_cuenta", "-u=#{u1.id}", "-m=#{moneda.id}", "-a=100.0"])
        Ledger.main(["alta_cuenta", "-u=#{u2.id}", "-m=#{moneda.id}", "-a=50.0"])
      end)

      args = [
        "realizar_transferencia",
        "-o=#{u1.id}",
        "-d=#{u2.id}",
        "-m=#{moneda.id}",
        "-a=30.0"
      ]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con deshacer_transaccion" do
      user =
        %UsuarioSchema{
          nombre: "Deshacer#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      {:ok, t} =
        capture_io(fn ->
          Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{moneda.id}", "-a=100.0"])
        end)
        |> then(fn _ ->
          FuncionesTransaccion.alta_cuenta(
            {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 50}}
          )
        end)

      args = ["deshacer_transaccion", "-id=#{t.id}"]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con ver_transaccion" do
      user =
        %UsuarioSchema{
          nombre: "VerTrans#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "USD#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      args = ["ver_transaccion", "-id=#{t.id}"]

      capture_io(fn ->
        assert {:ok, _} = Ledger.main(args)
      end)
    end

    test "main con editar_moneda" do
      moneda =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      args = ["editar_moneda", "-id=#{moneda.id}", "-p=1.5"]

      capture_io(fn ->
        assert :ok = Ledger.main(args)
      end)
    end

    test "main con ver_moneda" do
      moneda =
        %MonedaSchema{nombre: "BTC#{System.unique_integer([:positive])}", precio_usd: 30000.0}
        |> Repo.insert!()

      args = ["ver_moneda", "-id=#{moneda.id}"]

      capture_io(fn ->
        assert :ok = Ledger.main(args)
      end)
    end

    test "main con borrar_moneda" do
      moneda =
        %MonedaSchema{nombre: "XRP#{System.unique_integer([:positive])}", precio_usd: 0.5}
        |> Repo.insert!()

      args = ["borrar_moneda", "-id=#{moneda.id}"]

      output =
        capture_io(fn ->
          Ledger.main(args)
        end)

      assert output =~ "Moneda"
    end
  end

  describe "Output.Errors - casos adicionales" do
    test "error_usuario con delete_failed" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_usuario({:error, :delete_failed})
        end)

      assert output =~ "borrar_usuario"
      assert output =~ "No se pudo eliminar el usuario"
    end

    test "error_usuario con invalid_update" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_usuario({:error, :invalid_update})
        end)

      assert output =~ "editar_usuario"
      assert output =~ "No se pudo actualizar el usuario"
    end

    test "error_monedas con invalid_update" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_monedas({:error, :invalid_update})
        end)

      assert output =~ "editar_moneda"
      assert output =~ "No se pudo actualizar la moneda"
    end

    test "error_monedas con divisa_existe" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_monedas({:error, :divisa_existe})
        end)

      assert output =~ "crear_moneda"
      assert output =~ "nombre de la moneda ya se encuentra en uso"
    end

    test "error_transacciones con no_hay_transacciones" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_transacciones({:error, :balance, :no_hay_transacciones})
        end)

      assert output =~ "balance"
      assert output =~ "no tiene transacciones registradas"
    end

    test "error_transacciones con cuenta_ya_existe" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_transacciones({:error, :alta_cuenta, :cuenta_ya_existe})
        end)

      assert output =~ "alta_cuenta"
      assert output =~ "Ya existe una cuenta activa"
    end

    test "error_transacciones con tipo_no_soportado" do
      output =
        capture_io(fn ->
          Ledger.Output.Errors.error_transacciones({:error, :deshacer, :tipo_no_soportado})
        end)

      assert output =~ "deshacer"
      assert output =~ "error desconocido"
    end
  end

  describe "Parser.Usuarios - cobertura adicional" do
    test "parse_crear con error en parse_flags" do
      flags = ["-x=valor"]

      assert {:error, {:unknown_flag, "-x=valor"}} = Usuarios.parse_crear(flags)
    end

    test "parse_editar con error en parse_flags" do
      flags = ["-x=valor"]

      assert {:error, {:unknown_flag, "-x=valor"}} = Usuarios.parse_editar(flags)
    end

    test "parse_id con error en parse_flags" do
      flags = ["-x=valor"]

      assert {:error, {:unknown_flag, "-x=valor"}} = Usuarios.parse_id(flags)
    end
  end

  describe "Transacciones - casos de cobertura adicional" do
    setup do
      u1 =
        %UsuarioSchema{
          nombre: "Cov1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "Cov2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "COV#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      %{u1: u1, u2: u2, moneda: moneda}
    end

    test "alta_cuenta con error de inserción", %{u1: u1, moneda: moneda} do
      attrs = %{
        usuario_destino_id: u1.id,
        moneda_destino_id: moneda.id,
        monto: -100.0
      }

      assert {:error, :invalid_amount} = FuncionesTransaccion.alta_cuenta({:ok, attrs})
    end

    test "deshacer TRANSFERENCIA", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 200}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_transferencia(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             usuario_destino_id: u2.id,
             moneda_destino_id: moneda.id,
             monto: 50
           }}
        )

      {:ok, rev} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})

      assert rev.tipo == "TRANSFERENCIA"
      assert rev.usuario_origen_id == u2.id
      assert rev.usuario_destino_id == u1.id
    end

    test "deshacer SWAP", %{u1: u1} do
      m1 =
        %MonedaSchema{nombre: "SWA#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "SWB#{System.unique_integer([:positive])}", precio_usd: 2.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m2.id, monto: 100}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_swap(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             moneda_origen_id: m1.id,
             moneda_destino_id: m2.id,
             monto: 20
           }}
        )

      {:ok, rev} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})

      assert rev.tipo == "SWAP"
      assert rev.moneda_origen_id == m2.id
      assert rev.moneda_destino_id == m1.id
    end

    test "calcular balance con REVERSION_ALTA_CUENTA", %{u1: u1, moneda: moneda} do
      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})

      {:ok, balances} = FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id}})

      balance_moneda = Enum.find(balances, fn b -> b.moneda_id == moneda.id end)
      assert balance_moneda.total == 0.0
    end

    test "balance con moneda específica y conversión", %{u1: u1} do
      m1 =
        %MonedaSchema{nombre: "BAL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "BA2#{System.unique_integer([:positive])}", precio_usd: 2.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m2.id, monto: 50}}
      )

      output =
        capture_io(fn ->
          FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id, moneda_id: m1.nombre}})
        end)

      assert output =~ "Balance:"
    end

    test "swap en calcular_balance", %{u1: u1} do
      m1 =
        %MonedaSchema{nombre: "SW1#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "SW2#{System.unique_integer([:positive])}", precio_usd: 0.5}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m2.id, monto: 100}}
      )

      FuncionesTransaccion.realizar_swap(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           moneda_origen_id: m1.id,
           moneda_destino_id: m2.id,
           monto: 10
         }}
      )

      {:ok, balances} = FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id}})

      balance_m1 = Enum.find(balances, fn b -> b.moneda_id == m1.id end)
      balance_m2 = Enum.find(balances, fn b -> b.moneda_id == m2.id end)

      assert balance_m1.total == 90.0
      assert balance_m2.total == 120.0
    end

    test "transferencia en calcular_balance - usuario origen", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.realizar_transferencia(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           usuario_destino_id: u2.id,
           moneda_destino_id: moneda.id,
           monto: 30
         }}
      )

      {:ok, balances} = FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id}})

      balance = Enum.find(balances, fn b -> b.moneda_id == moneda.id end)
      assert balance.total == 70.0
    end

    test "transferencia en calcular_balance - usuario destino", %{
      u1: u1,
      u2: u2,
      moneda: moneda
    } do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.realizar_transferencia(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           usuario_destino_id: u2.id,
           moneda_destino_id: moneda.id,
           monto: 30
         }}
      )

      {:ok, balances} = FuncionesTransaccion.balance({:ok, %{usuario_id: u2.id}})

      balance = Enum.find(balances, fn b -> b.moneda_id == moneda.id end)
      assert balance.total == 80.0
    end

    test "error en obtener_moneda_id_opcional" do
      u1 =
        %UsuarioSchema{
          nombre: "Err#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      output =
        capture_io(fn ->
          FuncionesTransaccion.balance({:ok, %{usuario_id: u1.id, moneda_id: "NOEXISTE"}})
        end)

      assert output =~ "error"
    end
  end

  describe "Transacciones - listar_transacciones" do
    setup do
      u1 =
        %UsuarioSchema{
          nombre: "Lista1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "Lista2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "LST#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      %{u1: u1, u2: u2, moneda: moneda}
    end

    test "listar todas las transacciones sin filtro", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      assert {:ok, transacciones} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: nil}})

      assert length(transacciones) >= 2

      assert Enum.all?(transacciones, fn t ->
               t.usuario_origen != nil or t.usuario_destino != nil
             end)
    end

    test "listar transacciones de usuario específico", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.realizar_transferencia(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           usuario_destino_id: u2.id,
           moneda_destino_id: moneda.id,
           monto: 30
         }}
      )

      assert {:ok, transacciones} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: u1.id}})

      assert length(transacciones) >= 2

      assert Enum.all?(transacciones, fn t ->
               t.usuario_origen_id == u1.id or t.usuario_destino_id == u1.id
             end)
    end

    test "listar transacciones de usuario sin transacciones", %{u1: _u1} do
      usuario_nuevo =
        %UsuarioSchema{
          nombre: "SinTrans#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      assert {:ok, transacciones} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: usuario_nuevo.id}})

      assert transacciones == []
    end

    test "listar transacciones con usuario inexistente" do
      assert {:error, [listar: "No se encontró el usuario."]} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: -1}})
    end

    test "listar transacciones incluye preload de relaciones", %{u1: u1, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      assert {:ok, [transaccion | _]} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: u1.id}})

      assert transaccion.usuario_destino != nil
      assert transaccion.moneda_destino != nil
      assert is_binary(transaccion.usuario_destino.nombre)
    end

    test "listar todas las transacciones con múltiples usuarios", %{
      u1: u1,
      u2: u2,
      moneda: moneda
    } do
      u3 =
        %UsuarioSchema{
          nombre: "Lista3#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u3.id, moneda_destino_id: moneda.id, monto: 75}}
      )

      assert {:ok, transacciones} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: nil}})

      usuarios_ids =
        transacciones
        |> Enum.flat_map(fn t ->
          [t.usuario_origen_id, t.usuario_destino_id]
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      assert u1.id in usuarios_ids
      assert u2.id in usuarios_ids
      assert u3.id in usuarios_ids
    end

    test "listar transacciones con diferentes tipos", %{u1: u1, u2: u2, moneda: moneda} do
      m2 =
        %MonedaSchema{nombre: "EUR#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m2.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.realizar_transferencia(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           usuario_destino_id: u2.id,
           moneda_destino_id: moneda.id,
           monto: 30
         }}
      )

      FuncionesTransaccion.realizar_swap(
        {:ok,
         %{
           usuario_origen_id: u1.id,
           moneda_origen_id: moneda.id,
           moneda_destino_id: m2.id,
           monto: 10
         }}
      )

      assert {:ok, transacciones} =
               FuncionesTransaccion.listar_transacciones({:ok, %{id: u1.id}})

      tipos = Enum.map(transacciones, & &1.tipo) |> Enum.uniq()

      assert "ALTA_CUENTA" in tipos
      assert "TRANSFERENCIA" in tipos
      assert "SWAP" in tipos
    end
  end

  describe "Output - listar_transacciones" do
    setup do
      u1 =
        %UsuarioSchema{
          nombre: "Out1#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      u2 =
        %UsuarioSchema{
          nombre: "Out2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "OUT#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      %{u1: u1, u2: u2, moneda: moneda}
    end

    test "output listar transacciones vacío" do
      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:listar_transacciones, []})
        end)

      assert output =~ "No hay transacciones registradas"
    end

    test "output listar transacciones con una transacción", %{u1: u1, moneda: moneda} do
      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:listar_transacciones, [t]})
        end)

      assert output =~ "Transacción ID: #{t.id}"
      assert output =~ "ALTA_CUENTA"
      assert output =~ "100"
    end

    test "output listar múltiples transacciones", %{u1: u1, u2: u2, moneda: moneda} do
      {:ok, t1} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      {:ok, t2} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:listar_transacciones, [t1, t2]})
        end)

      assert output =~ "Transacción ID: #{t1.id}"
      assert output =~ "Transacción ID: #{t2.id}"
      assert output =~ "100"
      assert output =~ "50"
    end

    test "output listar transacciones con TRANSFERENCIA", %{u1: u1, u2: u2, moneda: moneda} do
      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: moneda.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u2.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_transferencia(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             usuario_destino_id: u2.id,
             moneda_destino_id: moneda.id,
             monto: 30
           }}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:listar_transacciones, [t]})
        end)

      assert output =~ "TRANSFERENCIA"
      assert output =~ "Usuario origen:"
      assert output =~ "Usuario destino:"
    end

    test "output listar transacciones con SWAP", %{u1: u1} do
      m1 =
        %MonedaSchema{nombre: "SW1#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      m2 =
        %MonedaSchema{nombre: "SW2#{System.unique_integer([:positive])}", precio_usd: 1.2}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m1.id, monto: 100}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: u1.id, moneda_destino_id: m2.id, monto: 100}}
      )

      {:ok, t} =
        FuncionesTransaccion.realizar_swap(
          {:ok,
           %{
             usuario_origen_id: u1.id,
             moneda_origen_id: m1.id,
             moneda_destino_id: m2.id,
             monto: 10
           }}
        )

      output =
        capture_io(fn ->
          Ledger.Output.Output.handle({:listar_transacciones, [t]})
        end)

      assert output =~ "SWAP"
      assert output =~ "Moneda origen:"
      assert output =~ "Moneda destino:"
    end
  end

  describe "Ledger.main - listar_transacciones" do
    test "main con listar_transacciones sin usuario" do
      user =
        %UsuarioSchema{
          nombre: "ListMain#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "LIS#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      capture_io(fn ->
        Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{moneda.id}", "-a=100.0"])
      end)

      args = ["listar_transacciones"]

      capture_io(fn ->
        result = Ledger.main(args)
        assert match?({:ok, _}, result)
      end)
    end

    test "main con listar_transacciones de usuario específico" do
      user =
        %UsuarioSchema{
          nombre: "ListMain2#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "LI2#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      capture_io(fn ->
        Ledger.main(["alta_cuenta", "-u=#{user.id}", "-m=#{moneda.id}", "-a=100.0"])
      end)

      args = ["listar_transacciones", "-c1=#{user.id}"]

      output =
        capture_io(fn ->
          assert {:ok, _} = Ledger.main(args)
        end)

      assert output =~ "Transacción ID:"
    end

    test "main con listar_transacciones de usuario sin transacciones" do
      user =
        %UsuarioSchema{
          nombre: "ListSin#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      # ← cambiamos -id a -c1
      args = ["listar_transacciones", "-c1=#{user.id}"]

      output =
        capture_io(fn ->
          assert {:ok, _} = Ledger.main(args)
        end)

      assert output =~ "No hay transacciones registradas"
    end

    test "main con listar_transacciones usuario inexistente" do
      args = ["listar_transacciones", "-id=-1"]

      output =
        capture_io(fn ->
          Ledger.main(args)
        end)

      assert output =~ "error"
    end
  end

  describe "Usuarios - casos de cobertura adicional" do
    test "editar usuario con error de actualización" do
      user =
        %UsuarioSchema{
          nombre: "EditErr#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      nombre_duplicado = "Duplicado#{System.unique_integer([:positive])}"

      %UsuarioSchema{nombre: nombre_duplicado, fecha_nacimiento: ~D[1990-01-01]}
      |> Repo.insert!()

      output =
        capture_io(fn ->
          FuncionesUsuario.editar_usuario({:ok, %{id: user.id, nuevo_nombre: nombre_duplicado}})
        end)

      assert output =~ "error"
    end

    test "borrar usuario con error de delete" do
      user =
        %UsuarioSchema{
          nombre: "DelErr#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      output =
        capture_io(fn ->
          FuncionesUsuario.borrar_usuario({:ok, %{id: user.id}})
        end)

      assert output =~ "Usuario ID:"
    end
  end

  describe "Casos edge adicionales" do
    test "balance con múltiples transacciones del mismo tipo" do
      user =
        %UsuarioSchema{
          nombre: "Multi#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "MUL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 50}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 30}}
      )

      FuncionesTransaccion.alta_cuenta(
        {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 20}}
      )

      {:ok, balances} = FuncionesTransaccion.balance({:ok, %{usuario_id: user.id}})

      balance = Enum.find(balances, fn b -> b.moneda_id == moneda.id end)
      assert balance.total == 100.0
    end

    test "última transacción con usuario_origen_id nil" do
      user =
        %UsuarioSchema{
          nombre: "NilOrigen#{System.unique_integer([:positive])}",
          fecha_nacimiento: ~D[1990-01-01]
        }
        |> Repo.insert!()

      moneda =
        %MonedaSchema{nombre: "NIL#{System.unique_integer([:positive])}", precio_usd: 1.0}
        |> Repo.insert!()

      {:ok, t} =
        FuncionesTransaccion.alta_cuenta(
          {:ok, %{usuario_destino_id: user.id, moneda_destino_id: moneda.id, monto: 100}}
        )

      assert {:ok, _} = FuncionesTransaccion.deshacer_transaccion({:ok, %{id: t.id}})
    end
  end
end
