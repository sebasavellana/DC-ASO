$ErrorActionPreference = "Stop"

$usersfile = Import-Csv "C:\Users\Administrador\Documents\UsuariosWindowsServer.csv"
$deptfile = Import-Csv "C:\Users\Administrador\Documents\Departamentos.csv"

foreach ($line in $deptfile){
    # Campos a utilizar del fichero CSV
    $departamento = $line.NombreDepartamento
    # 1.1 - Crear el directorio compartido
     try{
        New-Item -Type Directory -Path ("C:\Compartidas\" + $departamento)
    }
    catch [System.IO.IOException] {
        Write-Output "Directorio compartido de departamento creado"
    } 
    # 1.2 - Crear grupos de AD
    try {
        New-ADGroup -Name $departamento -GroupScope Global -DisplayName $departamento
    }
    catch [Microsoft.ActiveDirectory.Management.ADException] {
        Write-Output "Grupo de AD creado"
    } 
    # 1.3 - Crear la compartición en SMB
    try {
        New-SmbShare -Name ("Departamento" + $departamento) -Path ("C:\Compartidas\" + $departamento) -ErrorAction Stop
    }
    catch [Microsoft.Management.Infrastructure.CimException] {
        Write-Output "Compartición ya creada"
    }
    # 1.4 - Darle permisos de acceso a cada grupo y eliminar a Todos
    Grant-SmbShareAccess -Name ("Departamento" + $departamento) -AccessRight Change -AccountName $departamento -Force
    Revoke-SmbShareAccess -Name ("Departamento" + $departamento) -AccountName Todos -Force
    # 1.5 Crear Unidad Organizativa para cada departamento
    try{
        New-ADOrganizationalUnit -Name $departamento
    }
    catch [Microsoft.ActiveDirectory.Management.ADException] {
        Write-Output ("Unidad organizativa " + $departamento + " ya creada")
    }
}

# 2 - Creación del contenedor de los directorios personales de los usuarios
try {
    New-Item -Type Directory -Path "C:\Compartida\Usuarios\"
}
catch [System.IO.IOException] {
    Write-Output "Directorio base de comparticiones creado"
}

foreach ($user in $usersfile) {
    # 3.0 - Variables con los campos a utilizar en el script
    $departamento = $user.Departamento
    $usuario = $user.NombreUsuario
    $pass = $user.Password
    # 3.1 - Crear directorio personal de cada usuario
    try {
        New-Item -Type Directory -Path ("C:\Compartida\Usuarios\" + $departamento + "\" + $usuario)
    }
    catch [System.IO.IOException] {
        Write-Output ("Directorio personal del usuario " +  $usuario + " ya creado")
    }
    # 3.2 - Crear usuario de dominio
    try {
        New-AdUser -Name $usuario -AccountPassword (ConvertTo-SecureString $pass -AsPlainText -Force) -Enabled:$true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
        Write-Output ("Usuario de Active Directory " + $usuario + " ya creado")
    }
    # 3.3 - Añadir usuario al grupo que le corresponde
    Add-ADGroupMember -Identity $user.Departamento -Members $usuario
    # 3.4 - Crear compartición en Samba para cada usuario
    try {
        New-SmbShare -Name  $usuario -Path ("C:\Compartida\Usuarios\" +  $departamento + "\" +$usuario) -ErrorAction Stop
    }
    catch [Microsoft.Management.Infrastructure.CimException] {
        Write-Output "Compartición de SMB ya creada"
    }
    # 3.5 - Corregir permisos para cada compartición
    Grant-SmbShareAccess -Name $usuario -AccountName $usuario -AccessRight Full -Force
    Revoke-SmbShareAccess -Name $usuario -AccountName Todos -Force
    # 3.6 - Mover usuario a su unidad organizativa
    try {
        $dnidentity = "CN=" + $usuario + ",CN=Users,DC=asir,DC=lan"
        $dntarget = "OU=" + $departamento + ",DC=asir,DC=lan"
        Move-ADObject -Identity $dnidentity -TargetPath $dntarget
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        Write-Output "Objeto ya movido a su UO"
    }
}
