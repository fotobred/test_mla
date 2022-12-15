#!/usr/bin/perl -D1

#################################################### mla.pl #
# <title> монитор для работы с логом почты </title>
#        out -  файл лога почты
# 		 преобразование out в .MySQL 
#        
###################################################################

use Time::Local;
use JSON::PP;
use utf8;
use lib "./";
use Mlam;
 my $mq = "";

	
#  	sub cntrl_file_attr - получение атрибутов последнего считанного лога
#	подключение и чтение из базы атрибутов последнего считанного лога
#	если данные не сошлись - обновляю базу
	cntrl_file_attr(); 

    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "GET") { 
       $mq = $ENV{'QUERY_STRING'} ;
    }
		
	if ( $mq ) {						# если есть запрос - надо искать ответы
       find_mq( $ENV{'QUERY_STRING'} );	# поиск записей по запросу
	}
	   
	$Mlam::bD{'work_time'} = time() - $^T;  # время исполнения запроса 
	
	$json = encode_json \%Mlam::bD ;	# перевод хеша в JSON 
	http_user(); 						# вывод Content-Type для http клиента
	print $json ;						# вывод ответа

exit;