import pandas
import subprocess, sys

try:
    dfusers = pandas.read_csv("/root/pandas/usuariossamba.csv")
    dfdepts = pandas.read_csv("/root/pandas/departamentos.csv")
except:
    print("Fichero de datos no encontrado")
    sys.exit()

depts = dfdepts.values.tolist()

# Creación de grupos departamentales y unidades organizativas
for item in depts:
    subprocess.run(["samba-tool","group","add",item[0]])
    uoname = "OU=" + item[0]
    subprocess.run(["samba-tool","ou","create",uoname])

users = dfusers.values.tolist()
# 5 es username, 6 es password, 8 es el departamento al que pertenecen

# Creación de usuarios, activación y adición al grupo del departamento y su OU
# Además, informática serán Administradores del Dominio
for item in users:
    subprocess.run(["samba-tool","user","create",item[5],item[6]])
    subprocess.run(["samba-tool","user","enable",item[5]])
    subprocess.run(["samba-tool","group","addmembers",item[8],item[5]]) 
    uoname = "OU=" + item[8]
    subprocess.run(["samba-tool","user","move",item[5],uoname])
    if item[8] == "Informatica":
        subprocess.run(["samba-tool","group","addmembers","Domain Admins",item[5]])
