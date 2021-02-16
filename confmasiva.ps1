$deptfile = Import-Csv "C:\Users\Administrador\Documents\Departamentos.csv"

# ¿Qué se tiene que ejecutar una vez?
# ¿Qué se tiene que ejecutar para cada línea del fichero?

foreach ($line in $deptfile){
    # 1.1 - Crear el directorio compartido
    New-Item -Type Directory -Path ("C:\Compartida\" + $line.NombreDepartamento)
    # 1.2 - Crear grupos de AD
    New-ADGroup -Name $line.NombreDepartamento -GroupScope Global -DisplayName $line.NombreDepartamento
    # 1.3 - Crear la compartición en SMB
    New-SmbShare -Name ("Departamento" + $line.NombreDepartamento) -Path ("C:\Compartida\" + $line.NombreDepartamento)
    # 1.4 - Darle permisos de acceso a cada grupo y eliminar a Todos
    Grant-SmbShareAccess -Name ("Departamento" + $line.NombreDepartamento) -AccessRight Change -AccountName $line.NombreDepartamento -Force
    Revoke-SmbShareAccess -Name ("Departamento" + $line.NombreDepartamento) -AccountName Todos -Force
}
