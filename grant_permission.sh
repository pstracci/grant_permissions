#!/bin/bash

# Autor: Paulo Stracci
# Data: 28/11/2018
# Descrição: Este programa é resposável por receber o nome de uma tabela e
#			 conceder permissão para o db_link do BSCS-IX --> INTERFACES-IX
#			 e vice-versa.
#
# Licença: GNU General Public License (GPL)
# -----------------------------------------------------------------------------
# Histórico de versões
#
# Versão 1: Criação do Programa
# Versão 2: Inclusão de variáveis no arquivo cfg
# Versão 3: Alteração do case de opções para utilizar o getopts
# Versão 4: Adicionado tratamento de erro do Oracle
# -----------------------------------------------------------------------------


config_file=`$( echo basename "$0") | sed s/\.sh/\.cfg/g`


# Função que imprime os dados na tela
AddOutput () {

echo "["`date "+%d/%m/%Y %H:%M:%S"`"] - $1"
                
}

# Função que retorna o erro do SQL
CaptureSqlError () {

	sql_return_code=$1
	test $sql_return_code -ne 0 && echo "Erro no sql. Código ORA no shell: "$sql_return_code"" && exit 1
            
}

BASE_BSCS=`grep BASE_BSCS $config_file | cut -d= -f 2`
BASE_INTERFACES=`grep BASE_INTERFACES $config_file | cut -d= -f 2`
USUARIO_CBCF=`grep USUARIO_CBCF $config_file | cut -d= -f 2`
USUARIO_RPCC=`grep USUARIO_RPCC $config_file | cut -d= -f 2`
USUARIO_BCFADM=`grep USUARIO_BCFADM $config_file | cut -d= -f 2`
SENHA_BCFADM=`grep SENHA_BCFADM $config_file | cut -d= -f 2`
SENHA_RP=`grep -i ^rpcc /interfaces_ix/.interfaces.passwd | cut -d, -f 2 | cut -d= -f 2`
SENHA_CBCF=`grep -i ^cbcf.massa /interfaces_ix/.interfaces.passwd | cut -d, -f 2 | cut -d= -f 2`

MENSAGEM_USO="
Uso: $(basename "$0") [-t TABELA] [-o ORIGEM] [-d DESTINO] | [OPÇÕES]

OPÇÕES:
	-t	Tabela que receberá a permissão de acesso
	-o	Schema em que a tabela foi criada
	-d	Schema que irá consulta-la
	-h	Mostra essa tela de ajuda e sai
	-V	Mostra a versão do programa
	
	Exemplo: 
	
	1) Criei uma tabela no BCFADM e quero acessa-la no schema RP:
	   $0 -t TABELA -o BCFADM -d RP 
	
	2) Criei uma tabela no CBCF e quero acessa-la no schema BCFADM:
	   $0 -t TABELA -o CBCF -d BCFADM 
	   
	 *** Atualmente suporte os schemas BCFADM, CBCF e RP ***
"

while getopts ":t:o:d:hV" opcao
do
case "$opcao" in

	t) tabela="$OPTARG"  ;;
	o) origem="$OPTARG"  ;;
	d) destino="$OPTARG" ;;
	h) 
	   echo "$MENSAGEM_USO" 
	   exit 0;;
	V) 
	   echo -n $(basename "$0")":"
	   grep '^# Versão ' "$0" | tail -1 | cut -d: -f 1 | tr -d \#
	   exit 0;;
	\?) 
	   AddOutput "Opção inválida: "$OPTARG""
	   exit 1;;
	:) 
	   AddOutput "Faltou o parâmetro para a opção "$OPTARG"!"
	   exit 1
	;;
esac
done


if [ -z $tabela  ] || [ -z $origem  ] || [ -z $destino ]
then

	echo "Favor informar todos os parâmetros obrigatórios: -t, -o, -d !"
	exit 1
fi


# Se a tabela estiver no BSCSIX - concede permissão para os usuários dos db_links de INTERFACES

if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_BCFADM ]
then  
	sqlplus -s $USUARIO_BCFADM/$SENHA_BCFADM@$BASE_BSCS   << ENDBLOCK
	
	WHENEVER SQLERROR EXIT SQL.SQLCODE;
	GRANT SELECT ON $tabela TO RMT_RP_INTIXP1;
	GRANT SELECT ON $tabela TO RMT_CBCF_INTIXP1;
ENDBLOCK
	CaptureSqlError $?

fi

# Se a tabela estiver no BSCSIX - concede permissão para os usuários dos db_links de INTERFACES

if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_CBCF ] || [ $(echo $origem  | tr a-z A-Z) = $USUARIO_RPCC ]
then  

	if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_CBCF ] 
		then
		sqlplus -s $USUARIO_CBCF/$SENHA_CBCF@$BASE_INTERFACES   << ENDBLOCK
	
	WHENEVER SQLERROR EXIT SQL.SQLCODE;
	GRANT SELECT ON $tabela TO RMT_BCFADM_BSCSIXP1;
ENDBLOCK
	CaptureSqlError $?

	fi

	if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_RPCC ] 
		then
		sqlplus -s $USUARIO_RPCC/$SENHA_RP@$BASE_INTERFACES   << ENDBLOCK
	
	WHENEVER SQLERROR EXIT SQL.SQLCODE;
	GRANT SELECT ON $tabela TO RMT_BCFADM_BSCSIXP1;
ENDBLOCK
	CaptureSqlError $?
	
	fi
	
fi

# Verifica qual o db_link deverá ser usado para acessar a tabela
test $(echo $destino  | tr a-z A-Z) = $USUARIO_CBCF && db_link_sugerido=LK_BSCSIXP1_BCFADM_01
test $(echo $destino  | tr a-z A-Z) = $USUARIO_RPCC && db_link_sugerido=LK_BSCSIXP1_BCFADM_02
test $(echo $destino  | tr a-z A-Z) = $USUARIO_BCFADM && db_link_sugerido=LK_BSCS62P1_SYSADM_04


if [ -z $db_link_sugerido ] 
then
	AddOutput 'Permissão concedida para a tabela '$tabela 
else
	AddOutput 'Permissão concedida para a tabela '$tabela'. Para acessa-la, utilize o DB_LINK: '$db_link_sugerido'. ' 
fi

exit 0
