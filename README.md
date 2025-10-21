# Ledger

Sistema de libro contable que registra transacciones de diferentes monedas entre usuarios. El sistema utiliza una base de datos PostgreSQL con Ecto para gestionar usuarios, monedas y transacciones.

## Requisitos

- Elixir 1.12 o superior
- Erlang/OTP 24 o superior
- Docker y Docker Compose (para la base de datos)
- Make

## Instalación

1. Clonar el repositorio

2. Crear el programa con Makefile:
```bash
make create
```

Esto generará un ejecutable llamado ledger en el directorio raíz del proyecto y dejará lista la base de datos para ser utilizada.

Comandos Disponibles del Makefile

```bash
make create - Crea el proyecto, levanta la base de datos y crea el ejecutable para utilizar
make db - Inicia la base de datos con Docker
make stop - Detiene la base de datos
make test - Ejecuta los tests con cobertura
make compile - Compila el proyecto
make clean - Limpia los archivos compilados
make escript - Genera el ejecutable
make build - Limpia, compila y genera el ejecutable
make all - Alias de make build
```

## Uso
#### Gestión de Usuarios
- Crear usuario:
```bash
./ledger crear_usuario -n=NombreUsuario -b=DD-MM-YYYY
```
- Editar usuario:
```bash
./ledger editar_usuario -id=ID -n=NuevoNombre
```
- Ver usuario
```bash
./ledger ver_usuario -id=ID
```
- Borrar usuario (si no tiene transacciones realizadas)
```bash
./ledger borrar_usuario -id=ID
```

#### Gestión de Monedas
- Crear moneda:

```bash
./ledger crear_moneda -n=SIMBOLO -p=PRECIO_USD
```

- Editar moneda:
```bash
./ledger editar_moneda -id=ID -p=NUEVO_PRECIO
```
- Ver moneda:
```bash
./ledger ver_moneda -id=ID
```
#### Transacciones
- Alta de cuenta (crear cuenta para un usuario en una moneda):
```bash
./ledger alta_cuenta -u=USUARIO_ID -m=MONEDA_ID -a=MONTO_INICIAL
```
- Realizar una transferencia
```bash
./ledger realizar_transferencia -o=USUARIO_ORIGEN_ID -d=USUARIO_DESTINO_ID -m=MONEDA_ID -a=MONTO
```
- Realizar un swap
```bash
./ledger realizar_swap -u=USUARIO_ID -mo=MONEDA_ORIGEN_ID -md=MONEDA_DESTINO_ID -a=MONTO
```
- Ver una transacción especifica
```bash
./ledger ver_transaccion -id=TRANSACCION_ID
```
- Deshacer la ultima transacción realizada por un usuario
```bash
./ledger deshacer_transaccion -id=TRANSACCION_ID
```

> [!NOTA]
> Solo se puede deshacer la última transacción realizada por los usuarios involucrados.

- Listar transacciones:
```bash
./ledger listar_transacciones
```
- Listar las transacciones de un usuario especifico
```bash
./ledger listar_transacciones -c1=USUARIO_ID
```
- Calcular el balance de un usuario 
```bash
./ledger balance -c1=USUARIO_ID
```
- Calcular el balance de un usuario en una moneda especifica
```bash
./ledger balance -c1=USUARIO_ID -m=NOMBRE_MONEDA
```

### EJEMPLOS
### Crear usuarios
```bash
./ledger crear_usuario -n=Juan -b=15-05-1990
./ledger crear_usuario -n=Maria -b=20-08-1985
```

### Crear monedas
```bash
./ledger crear_moneda -n=BTC -p=55000
./ledger crear_moneda -n=USDT -p=1
./ledger crear_moneda -n=ARS -p=0.0012
```

### Dar de alta cuentas
```bash
./ledger alta_cuenta -u=1 -m=1 -a=1.5
./ledger alta_cuenta -u=1 -m=2 -a=10000
./ledger alta_cuenta -u=2 -m=2 -a=5000
```

### Realizar transferencia
```bash
./ledger realizar_transferencia -o=1 -d=2 -m=2 -a=1000
```

### Realizar swap
```bash
./ledger realizar_swap -u=1 -mo=2 -md=1 -a=5000
```

### Consultar balance
```bash
./ledger balance -c1=1
./ledger balance -c1=1 -m=BTC
```

### Ver transacciones
```bash
./ledger listar_transacciones
./ledger listar_transacciones -c1=1
```

## Errores Manejados
#### Errores de Usuario
`:user_exists` - El nombre de usuario ya existe

`:user_not_found` - Usuario no encontrado

`:invalid_age` - El usuario debe ser mayor de 18 años

`:same_name` - El nuevo nombre es igual al actual

`:user_has_transactions` - No se puede borrar un usuario con transacciones

`:delete_failed`- Error al eliminar usuario

#### Errores de Moneda

`:nombre_corto` - El nombre debe tener al menos 3 letras

`:nombre_largo` - El nombre no puede tener más de 4 letras

`:nombre_formato_invalido` - El nombre debe estar en mayúsculas

`:divisa_existe` - La moneda ya existe

`:precio_invalido` - El precio debe ser positivo

`:moneda_not_found` - Moneda no encontrada

#### Errores de Transacción

`:invalid_amount` - El monto debe ser positivo

`:insufficient_funds` - Fondos insuficientes

`:cuenta_origen_no_existe` - La cuenta origen no existe

`:cuenta_destino_no_existe` - La cuenta destino no existe

`:not_found` - Transacción no encontrada

`:not_last` - Solo se puede deshacer la última transacción

#### Errores de Parsing

`:invalid_integer` - Valor entero inválido

`:invalid_float` - Valor decimal inválido

`:missing_flags` - Flags requeridos faltantes

`:unknown_flag` - Flag desconocido

`:invalid_subcommand` - Subcomando inválido

## Tests
Para ejecutar los tests con cobertura:
```bash
make test
```

***Notas Importantes***

- Los usuarios deben ser mayores de 18 años
- Los nombres de monedas deben tener entre 3 y 4 caracteres en mayúsculas
- Solo se pueden borrar usuarios sin transacciones registradas
- Las transacciones son inmutables, pero se pueden revertir con el comando de deshacer
- Solo se puede deshacer la última transacción de los usuarios involucrados
- Para realizar transferencias o swaps, ambos usuarios deben tener cuentas activas en las monedas correspondientes
