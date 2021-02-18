$deptfile = Import-Csv "C:\Users\Administrador\Documents\Departamentos.csv"

# ¿Qué se tiene que ejecutar una vez?
# ¿Qué se tiene que ejecutar para cada línea del fichero?

foreach ($line in $deptfile){
    # 1.1 - Eliminar las comparticiones de SMB
    Remove-SmbShare -Name ("Departamento" + $line.NombreDepartamento) -Force
    # 1.2 - Eliminar grupos de AD
    Remove-ADGroup -Identity $line.NombreDepartamento -Confirm:$false
    # 1.3 - Eliminar el directorio compartido
    Remove-Item -Path ("C:\Compartida\" + $line.NombreDepartamento)
}
