#!/usr/bin/perl -D1

####################################################   Mlam.pm   #
# <title> модуль для работы с логом почты </title>
#        out -  файл лога почты
# 		 преобразование out в .MySQL 
#        
###################################################################

#use strict;
package Mlam;
use utf8;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( http_user cntrl_file_attr find_mq ) ;

our %bD = ( 'name' => 'MLA BigData'  );  #  большой хэш ответа!
my $log_file = "./out";			#  файл лога почты

my %db = ();   					# параметры подключения к базе	
   $db{'host'} = "localhost";	# MySQL-сервер 
   $db{'port'} = "3306"; 		# порт, на который открываем соединение
   $db{'user'} = "user"; 		# имя пользователя
   $db{'pass'} = "12345"; 		# пароль
   $db{'db_n'} = "mla"; 		# имя базы данных

my $i   = 1;				# счетчик строк лога	
my $it  = 0;				# счетчик строк тестовой выдачи
my %stt = ();				# "статистика загрузки" базы данных 

my $otkom = 1;				# 1/0 показать/скрыть отладочные сообщения
my $user  = 0;				# пользователь в консоли 
   $user  = 1 if $ENV{'HTTP_USER_AGENT'} ne '';	# или пользователь В браузере

	sub print_t{			# вывод отладочных сообщений
		if ( $otkom ) {
			my $tt = shift ;
			if ( $user == 1 ) {
				$it++ ;
				$bD{'it'}->{ $it } = $tt ; 
			} else {
				print "  $tt \n" ;
			}
		}
	}

	sub print_T{			# вывод выделенных отладочных сообщений
		if ( $otkom ) {
			my $tt = shift ;
			if ( $user == 1 ) {
				$it++ ;
				$bD{'it'}->{ $it } = '>>>> '.$tt ; 
			} else {
				print "-------------\n".$tt." \n" ;
			}
		}
	}

	sub http_user{			# вывод загололвка для браузера 
		if ( $user == 1 ) {
			print "Content-Type: application/json\n\n";
		}  else {
			print " ######################### \n";
		}
	}	

	sub conn_db{			# подключение базы данных
        use DBI;

        $dbh = DBI->connect("DBI:mysql:$db{'db_n'}:$db{'host'}:$db{'port'}"
			,$db{'user'},$db{'pass'} ) 
			or error_conn_db();
		return $dbh ;
	}

	sub error_conn_db{		# ошибка подключения базы данных   		? -  переделать
		$otkom = 1; 	# принудительное включение показа сообщений
		my $t = "\n";
		if ( $user == 1 ) {
			print	"Content-Type: text/html\n\n"
					."<!DOCTYPE html>\n\n"
					."<meta charset='utf-8'>\n\n"
					."<body><pre>\n";
			$t = '<br>';
		} 
		print ( "$t$t  Произошла ошибка подключения к рабочей базе данных!"
				."$t	Пожалуйста проверьте:"
				."$t	- параметры подключения к MySQL-серверу;"
				."$t	- наличие базы данных mla ;"
				."$t	- данные пользователя базы mla ."
				."$t	При необходимости создайте базу с соответствующими таблицами. "
				."$t	Инструкция в файле mla.sql "
				."$t$t") ;

		exit ;
	}

	sub disc_db{			# отключение базы данных ?????
        use DBI;
		my $dbh = shift; 	# получаю дескриптор базы
        $dbh->disconnect;	# закрываю соединени
       # my $rc = $dbh->disconnect;  # закрываю соединени
	}

#  	sub cntrl_file_attr - получение атрибутов последнего считанного лога
#	подключение и чтение из базы атрибутов последнего считанного лога
	sub cntrl_file_attr{
        use DBI;

		my %faf = ( 'id' => 0 );			# задаю значение id, что бы не выделять его
											# из общего списка взятого из БД
		# получение списка атрибутов файла лога почты
		@faf{ 'dev','ino','mode','nlink','uid','gid','rdev','size','atime','mtime','ctime','blksize','blocks' } = stat($log_file);
        
		$dbh = conn_db();					# подключаю базу данных
        $sth = $dbh->prepare("SELECT * FROM file_attr WHERE id=0 ;");  # запрос на получение атрибутов последнего загруженного лога
        $sth->execute;			 			# выполняю запрос

		my $t = 0;							# счетчик совпадений и временное хранилище
        $ary = $sth->fetchrow_hashref();	# в ответе только одна строка
        $sth->finish;
		
		while ( ( $key, $val ) = each ( %$ary ) ) {		# 
		#	print_t ( '     '.$key.'  [ '.$val.' ] >< [ '.$faf{ $key }.' ]' );
			last if  $val ne $faf{ $key } ;
			$t++;
		}	
		# если количество совпадений меньше количества параметров 
		# то надо пополнить/обновить базу
		if ( $t < 5) {							
			fill_db( $dbh );				# заполню таблицы данными
       
			#  обновление данных последнего загруженного лога 
			$t = "UPDATE file_attr SET "
				." size = $faf{ size }, "
				." ctime = $faf{ ctime }, "
				." mtime = $faf{ mtime }, "
				." atime = $faf{ atime } "
				." WHERE id=0 ;";
		
			$sth = $dbh->prepare( $t );
			$t = $sth->execute; # выполняем запрос		
			$sth->finish;
		}
		
        disc_db( $dbh ); 	# отключаю базы данных
	}	

	sub fill_db{			# заполнение таблиц данными
        use DBI;
		my $dbh = shift;	# получаю дескриптор базы
		my $table = '';		# имя таблицы для записи строки лога
		my $q_str = ''; 	# строка запроса
		
        open ( INPUT_FILE, "<$log_file" )  || die "Can't open $log_file: $!\n";
		print_T ("fill_db:: открыли файл почтового лога");
		foreach (<INPUT_FILE>) {					# перебираю лог построчно
		    $llRef = line_an( $_ );					# анализ строки лога 
			
			if ( $llRef->{'flag'} eq '<='  ) {		# в таблицу message
				$llRef->{ id } = ''; 				# инициализация { id } 
				# для таблицы message надо найти фрагмент id
				my @line = reverse( split ( ' ', $llRef->{ str } ) ); # искомая информация обычно в конце строки
				foreach ( @line ) {
					if ( $_ =~ /id=.+$/ ) {			# если строка похожа на искомую  ( id=xxxxx )
						$_ =~ s/id=// ;				# убираю лишнее
						$llRef->{ id } = $_ ;		# сохраняю в общих данных 
						last ;						# прерываю цикл
					}
				}
			
				$q_str = "INSERT IGNORE INTO message SET "
			#	."message_id_pk = '$llRef->{ created } $llRef->{ int_id } $llRef->{ address }', " # index
				."created = '$llRef->{ created }', " # created
					 ."id = '$llRef->{ id }', "  	 # id
				 ."int_id = '$llRef->{ int_id }', "  # int_id
				   ."flag = '$llRef->{ flag }', " 	 # flag
				."address = '$llRef->{ address }', " # address
				    ."str = '$llRef->{ str }'" 		 # str
				." ;";
				$table = 'message';
			} else {								 # в таблицу log
				$q_str = "INSERT IGNORE INTO log SET "
				."log_id_pk = '$llRef->{ created } $llRef->{ int_id } $llRef->{ flag }', " # index
				."created = '$llRef->{ created }', " # created
				 ."int_id = '$llRef->{ int_id }', "  # int_id
				   ."flag = '$llRef->{ flag }', " 	 # flag
				."address = '$llRef->{ address }', " # address
				    ."str = '$llRef->{ str }'" 		 # str
				." ;";
				$table = 'log';
			}				
			add_table( $q_str, $dbh, $table  );	 # выполнение запроса на добавление записи
        }
		print_T ( 'Статистика добавления лога в база mla'  );
		print_t ( '=         всего  ( удачно )'  );
		print_t ( '=     all :: '. $stt{ 'all' }.' ok ( '. $stt{ 'all_ok' }.' )'  );
		print_t ( '= message :: '. $stt{ 'message' }.' ok ( '. $stt{ 'message_ok' }.' )'  );
		print_t ( '=     log :: '. $stt{ 'log' }.' ok ( '. $stt{ 'log_ok' }.' )'  );

	}

	sub add_table{			# выполнение запроса на добавление записи
	#	print_T ("add_table");
		my $q_str =  shift;		# стоока запроса
		my $dbh   =  shift;		# дескриптор базы данных
		my $table =  shift;		# таблица запроса

        $sth = $dbh->prepare( $q_str );
        $res = $sth->execute;	# выполняю запрос
		$stt{ 'all' } ++ ;
		$stt{ 'all_ok' } += $sth->rows;
		$stt{ $table } ++;
		$stt{ $table.'_ok' } += $sth->rows;

		if( $sth->rows == 0 ){	# если запрос не выполнен - вывод ситуации
			print_T ( 'Ошибка в добавлении.. строка лога:  '. $llRef->{'i'}
			.'  с флагом ['.$llRef->{'flag'}.'] '
			.'  в таблицу: '. $table  );
			print_t ( '> '. $llRef->{'line'}  );
			print_t( 'SQL: '. $q_str );
		}
        $sth->finish;
	}
	
	sub line_an {			# разбор строки лога
	    my $in = shift;							# получил строку для разбора
		my $ll;									# ссылка на хеш для хранения результатов
		$ll->{'i'} = $i;						# номер текущей строки
		$ll->{'line'} = $in;					# текущая строка
	    my @line = split ( ' ', $in );			# разделил строку по пробелам
	    my $date    	 = shift @line ;		# взял дату
	    my $time       	 = shift @line ;		# взял время
	    $ll->{'int_id'}  = shift @line ;		# взял int_id
	    $ll->{'flag'}    = shift @line ;		# взял флаг	
	    my $q1           = $line[0];			# взял 1 позиция адреса 
	    my $q2           = $line[1];			# взял 2 позиция адреса 
	    $ll->{'str'}     = join ( ' ', @line );	# взял остаток строки
	    $ll->{'created'} = $date.' '.$time  ;	# собрал поле 	created
		
		if ( q_mail( $q1 )  ) {  				# поиск почтового адреса в 2 позициях
			$ll->{'address'} = $q1 ; 			# адрес в 1 позиции
		} elsif ( q_mail( $q2 ) ){	
			$ll->{'address'} = $q2 ; 			# адрес во 2 позиции
		} else {	
			$ll->{'address'} = '' ; 			# адрес не найден
		}	
		$ll->{'address'} =~ s/<|>//g ;			# убрал лишние символы из адреса
		return $ll ;
	}

	sub q_mail{				# проверка на соответствие почтовому адресу
		my $in = @_[0];
		if ( $in =~ /^<*\w+@\w+\.\w+>*$/ ) {
		#	print_t ("q_mail: --->  это [ $in ] - почта ");
			return 1;
		} else {
		#	print_t ("q_mail: --->  это [ $in ] - НЕ почта ");
			return 0 ;
		}
	}

	sub find_mq{			# поиск записей по запросу

		my $mq = shift;						# данные для поиска
		my $i = 0;							# счетчик
		my $q_str = ''; 					# строка запроса

		print_t "есть запрос: ". $mq ;	
	
		$q_str = ""		# собираю запрос 
		."( SELECT created, address, int_id, flag, str FROM message "
		." WHERE address LIKE '%" .$mq. "%' )" #
		." UNION "
		."( SELECT created, address, int_id, flag, str FROM log "
		." WHERE address LIKE '%" .$mq. "%' )" #
		." ORDER BY int_id, created  "
		."  ;";
		
		$bD{'it'}{'SQL запрос'} =  $q_str ;	

		$dbh = conn_db();					# подключение базы данных
        $sth = $dbh->prepare( $q_str );		# запрос на выборку
        $sth->execute;			 			# выполняю запрос

        while( $ary = $sth->fetchrow_hashref() ) {			# перебираю ответ базы 
			$i++;											# нумерую строки в вывод
			while ( ( $key, $val ) = each ( %$ary ) ) {		# разбираю именованные поля
				$bD{'result'}->{ $i }->{ $key } = $val ;	# записываю результат в хэш ответа
			}
			$bD{'result'}->{ $i }->{ 'N' } = $i ;
		}
		$bD{'it'}{'найдено всего: '} =  $i ;	
		$bD{'it'}{'length'} =  $i ;	
		
        $sth->finish;
	}	
	

=comment1

запросы на очисmку mаблиц и "сброс" данных файла maillog

truncate table log;
truncate table message;
update file_attr set size = 1, ctime = 2, mtime = 3, atime = 4 where id=0;

=cut

1;