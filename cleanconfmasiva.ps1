$ErrorActionPreference = "Stop"

$deptfile = Import-Csv "C:\Users\Administrador\Documents\Departamentos.csv"

# ¿Qué se tiene que ejecutar una vez?
# ¿Qué se tiene que ejecutar para cada línea del fichero?

foreach ($line in $deptfile){
    $departamento = $line.NombreDepartamento
    # 1.1 - Eliminar las comparticiones de SMB
    try{
        Remove-SmbShare -Name ("Departamento" + $departamento) -Force -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]{
        Write-Output ("Compartición de " + $departamento + " ya eliminada")
    }
    # 1.2 - Eliminar grupos de AD
    try{
        Remove-ADGroup -Identity $departamento -Confirm:$false
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        Write-Output ("Grupo de AD " + $departamento + " ya eliminado")
    }
    # 1.3 - Eliminar el directorio compartido
    try {
        Remove-Item -Path ("C:\Compartida\" + $departamento)
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Output "Directorio compartido de departamento ya eliminado"
    }
}
