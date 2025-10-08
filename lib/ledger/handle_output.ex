defmodule Ledger.HandleOutput do
  def handle({:usuario, usuario}) do
    IO.puts("""
    ──────────────────────────────────────────────────────────────
      Usuario ID: #{usuario.id}
      Nombre: #{usuario.nombre}
      Fecha de nacimiento: #{usuario.fecha_nacimiento}
      Fecha de creación: #{usuario.fecha_creacion}
      Última edición: #{usuario.fecha_edicion}
    ──────────────────────────────────────────────────────────────
    """)
  end

  def handle({:moneda, moneda}) do
    IO.puts("""
    ──────────────────────────────────────────────────────────────
      Moneda ID: #{moneda.id}
      Nombre: #{moneda.nombre}
      Precio USD: #{moneda.precio_usd}
      Fecha de creación: #{moneda.fecha_creacion}
      Última edición: #{moneda.fecha_edicion}
    ──────────────────────────────────────────────────────────────
    """)
  end
end
