#!/bin/bash

# Autor: Paulo Stracci
# Data: 26/11/2018
# Descrição: Este programa é resposável por receber o nome de uma tabela e
#			 conceder permissão para o db_link do BSCS-IX --> INTERFACES-IX
#			 e vice-versa.
#
# Licença: GNU General Public License (GPL)
# -----------------------------------------------------------------------------
# Histórico de versões
#
# Versão 1: Criação do Programa
# -----------------------------------------------------------------------------

# Função que imprime os dados na tela
AddOutput () {

echo "["`date "+%d/%m/%Y %H:%M:%S"`"] - $1"
                
}

# Variáveis de Conexão
config_file=grant_permission.cfg

# Variáveis comentadas propositalmente
##BASE_BSCS=''
##BASE_INTERFACES=''
##USUARIO_CBCF='CBCF'
##USUARIO_RPCC='RP'
##USUARIO_BCFADM='BCFADM'
##SENHA_RP=``
##SENHA_CBCF=``
##SENHA_BCFADM=''

MENSAGEM_USO="
Uso: $(basename "$0") [-t TABELA | --tabela TABELA ] [-o ORIGEM | --origem ORIGEM] [-d DESTINO | --destino] [OPÇÕES]

OPÇÕES:
	-t, --tabela	Tabela que receberá a permissão de acesso
	-o, --origem	Schema em que a tabela foi criada
	-d, --destino	Schema que irá consulta-la
	-h, --help	Mostra essa tela de ajuda e sai
	-V, --version	Mostra a versão do programa
	
	Exemplo: 
	
	1) Criei uma tabela no BCFADM e quero acessa-la no schema RP:
	   $0 -t TABELA -o BCFADM -d RP 
	
	2) Criei uma tabela no CBCF e quero acessa-la no schema BCFADM:
	   $0 -t TABELA -o CBCF -d BCFADM 
	   
	 *** Atualmente suporte os schemas BCFADM, CBCF e RP ***
"

if [ $1 -z ]
then

	echo "$MENSAGEM_USO"
		exit 1
fi


while test -n "$1" 
do

	case "$1" in
		-t | --tabela )
		shift	
		tabela=$1	;;
		-o | --origem )
		shift	
		origem=$1	;;
		-d | --destino )
		shift	
		destino=$1	;;
		-h | --help ) echo "$MENSAGEM_USO"
		exit 0	;;
		-V | --version )	 grep '^# Versão ' "$0" | tail -1 | cut -d: -f 1 | tr -d \#
		exit 0	;;
		*) AddOutput "Opção inválida: "$1." Por favor seguir as orientações abaixo:"
		echo "$MENSAGEM_USO"
		exit 1	;;
	esac

	shift
	
done
 
test $(echo $destino  | tr a-z A-Z) = $USUARIO_CBCF && db_link_sugerido=LK_BSCSIXP1_BCFADM_01
test $(echo $destino  | tr a-z A-Z) = $USUARIO_RPCC && db_link_sugerido=LK_BSCSIXP1_BCFADM_02
test $(echo $destino  | tr a-z A-Z) = $USUARIO_BCFADM && db_link_sugerido=LK_BSCS62P1_SYSADM_04


# Se a tabela estiver no BSCSIX - concede permissão para os usuários dos db_links de INTERFACES

if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_BCFADM ]
then  
	sqlplus -s $USUARIO_BCFADM/$SENHA_BCFADM@$BASE_BSCS   << ENDBLOCK
	
	GRANT SELECT ON $tabela TO RMT_RP_INTIXP1;
	GRANT SELECT ON $tabela TO RMT_CBCF_INTIXP1;
ENDBLOCK

fi

# Se a tabela estiver no BSCSIX - concede permissão para os usuários dos db_links de INTERFACES

if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_CBCF ] || [ $(echo $origem  | tr a-z A-Z) = $USUARIO_RPCC ]
then  

	if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_CBCF ] 
		then
		sqlplus -s $USUARIO_CBCF/$SENHA_CBCF@$BASE_INTERFACES   << ENDBLOCK
	
	GRANT SELECT ON $tabela TO RMT_BCFADM_BSCSIXP1;
ENDBLOCK
	fi

	if [ $(echo $origem  | tr a-z A-Z) = $USUARIO_RPCC ] 
		then
		sqlplus -s $USUARIO_RPCC/$SENHA_RP@$BASE_INTERFACES   << ENDBLOCK
	
	GRANT SELECT ON $tabela TO RMT_BCFADM_BSCSIXP1;
ENDBLOCK
	fi
	
fi

AddOutput 'Permissão concedida para a tabela '$tabela'. Para acessa-la, utilize o DB_LINK: '$db_link_sugerido'. '

