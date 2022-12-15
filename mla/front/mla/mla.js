/*
*		mla.js - mail log analysis  - "основной" функционал 
*
*/

var MLA = MLA || {};
	
MLA = {
	
	gc: 0, 					// "глобальный" счетчик
	test_out: "yes", // "N" // режим вывода диагностики 
	X_lim: 100,				// максимальное количество результатов 
	X_page: 1,				// текущая страница 

	URL:  "http://192.168.1.78/cgi-bin/test/mla/mla.pl",
	X:	  		{},
	X_bD: 		{},
	X_length:	0,

	// cl() - вывод дополнительной отладочной информации со сквозной нумерацией
	// console.log ( gc + x ) 
	// x - информация для вывода
	cl( x ){
		t = this;
		if ( t.test_out != 'N'  ){
			//	console.log ('(-> ' + typeof( x ) + ' )' );
			if( typeof( x ) == 'string' ) {					// если "на входе" строка сообщения
				console.log( '( ' + t.gc++ + ' ) ' + x );	// выводим увеличенный счетчик и строку
			} else { 
				console.log( x );	// если "на входе" НЕ строка - выводим как объект
			}
			if( t.gc > 50020 ){		//  защита от "зацикливания"
				alert('Oy!');
			}
		}
	},
	
	//  ShowLoad() заставка на время загрузки данных с сервера
	//	параметр указывает показ заставки или выключение
	//	>=1 / 'load' / 'Load' / 'LOAD' - показ
	//	отрицательные числа и все остальные символы  -  выключение
	ShowLoad( j ) {  
		t = this;
		if ( j >= 1 || j == 'load' || j == 'Load' || j == 'LOAD'   ) {
			t.cl("----showLoad------ " + j + " ~~~~~~~~~~~~~~LOAD") ;
			$("#showLoad").removeClass("hide") ;  
		} else {
			t.cl("----showLoad------ " + j + " ~~~~~~~~~~~~~~END") ;
			$("#showLoad").addClass("hide") ;
		};
	},	


	//  decorate_one( X, templ ) - оформление одной записи по шаблону
	//   X  	-  оформляемая запись
	//   templ 	-  шаблон оформления
	decorate_one( X, templ ){  
		t = this;
		t.cl( 'decorate_one::templ: '+ templ +' ' ); 
		t.cl( X )
		
			var i = out = ''  ;
			if( !!templ ){ 				// проверка на наличие шаблона оформления
			//	templ = out;
				for( i in X ) {			// перебор записей
					if( typeof( X[i] ) == "object" ) {			// если имеем 'object'
						t.cl( 'decorate_one: ОШИБКА ---> [object]  <--- переход на следующий уровень --- ' );
						templ = t.decorate_one( X[i], templ );	// переходим на следующий уровень
					} else {
						if( typeof X[i] ) {						// если есть элемент 
							var rX = new RegExp( "#" + i + "#", 'g' );		// регулярное выражение для подстановки
								templ = templ.replace( rX , X[i]  );		// заменяем имена в шаблонах на значения
							//	t.cl( 'decorate_one: rX [' + rX + '] ----------->  tX [' + X[i] + '] ' ); t.cl( 'OUT:  ['+templ+']' );
						};			
					};
					if (  templ.search( /#/ )   < 0 ){	// провека на не заполненные поля в шаблоне
						t.cl ( 'decorate_one: шаблон [temp] заполнен:  ' + templ  );		
						break;							// если заполнять нечего - на выход
					} else {
				//		t.cl( 'decorate_one:templ::' + templ );
					};
				};
			} else { 
				t.cl( "Ошибка открытия шаблона оформления в decorate_one");
			//	alert( "Ошибка открытия шаблона оформления в decorate_one");
			};	
		return templ ;	
	},


	//	pagination( X_lim, X_length ) - постраничный навигатор
	//	X_lim	 - ограничение  на вывод результата
	//	X_length - количество результатов
	pagination( X_lim, X_length, line_first, line_end ) {
		let t = this;
		t.cl( 'pagination:: ' + X_lim + ' - ' + X_length+' - '+line_first+' - '+line_end  );	// зачистка "подвала"
		$('#bot').empty();					// зачистка "подвала"
	//	for( let i = 1; i <= X_lim; i++ ) {	// перебор записей 
	//	}
		$('#bot').append( '<div class="p_p" title='+(t.X_page-1)+'>'+(t.X_page-1)+'  &lt;&lt;&lt;</div>'		// вывод переходов
						 +'<div>'+line_first+' - '+line_end+' ( '+X_length + ' )</div>'							// по страницам
						 +'<div class="p_p" title='+(t.X_page*1+1)+'>&gt;&gt;&gt;  '+(t.X_page*1+1)+'</div>' );	// всё в "подвал"
	},	

	//	page_go( page ) - постраничный переход
	//	page - целевая страница
	page_go( page ) {
		let t = this;
		t.cl( 'page_go: '+ page );
		if ( ( page > 0 ) && ( page < t.X_length/t.X_lim )  ){
			t.X_page =  page ;
			t.decorate( );	//  передача ответа на оформление			
		}	
	},

	//  decorate( ) - обределение варианта оформления полученного набора записей
	decorate( ){  
		let t = this;
		let templ = '';				// шаблон оформления
		let X = t.X;				// набор записей
		let X_length = t.X_length ;	// количество полученных записей
		let X_lim = t.X_lim ;		// ограничение на вывод результата
		let line_first = 1;			// первая запись на странице 
		let line_end   = 1;			// последняя запись на странице 

		t.cl( 'decorate::X: ' ); 
		t.cl( X );
		var x = out = ''  ;

			t.cl( 'decorate::объем ответа: ' + X_length );
			if(  X_length > 1 ) {	// если много записей, то передаем на оформление по одной
				templ = t.templ_all ;
				if ( X_length < X_lim ) { 
					X_lim = X_length; 			// ограничение показываемого списка
				} 
				
				t.cl( 'decorate:: шаблон оформления: '+ templ +' ' ); 
				if( !!templ ){ 			// проверка на наличие шаблона оформления
					$('#work_zone').empty();					// зачистка work_zone
					line_first = (t.X_page - 1) * t.X_lim + 1 ;			// первая запись
					line_end   = t.X_page * t.X_lim ;					// последняя расчетная запись
					if ( line_end > X_length) { line_end = X_length  }	// правка количества циклов
					for( let i = line_first; i <= line_end; i++ ) {		// перебор записей 
						let x = X[i] ;							// текущая запись	
						if( typeof( x ) == "object" ) {			// если имеем 'object'
							t.cl( 'decorate: -> [object] - передаем на оформление ' );
							out = t.decorate_one( x, templ );	// переход на оформление элемента
						};
						t.cl( 'out:' + out );
						$('#work_zone').append( out );			// список элементов размещается в work_zone
					};
				};
				t.cl('page:: '+t.X_page+' ferst line:'+line_first+' end line: '+line_end );	// перебор записей 
				t.pagination( X_lim, X_length, line_first, line_end ); // обработка "постраничности"

			} else if(  X_length == 1 ) {	 // если в данных один ответ - передаем вывод в show_one
				t.show_one( X[0] );				
			} else if(  X_length == 0 ) {	 // если в данных 0 - очищаем поля
					$('#work_zone').empty(); // зачистка work_zone
					$('#bot').empty();		 // зачистка bot
			
			} else {
				t.cl( "Ошибка обработки данных в decorate");
			};	
		return X ;	
	},

	// показ данных в окне
	show_one( x ){
		let out = '',
			t = this;
		t.cl( 'show_one:: данные для отображения' );  t.cl( x );
		$( '#show_zone' ).addClass('show');		// показ элемента
		$( '#show_zone  #text_zone' ).empty();	// очистка элемента
		out = t.decorate_one( x, t.templ_one );	// переход на оформление элемента/персоны					
		$( '#show_zone #text_zone').append( out );		// "публикация" информации
	},

	// закрытие окна
	close_show_one( x ){
		$( '#mla #show_zone' ).removeClass('show');
		$( '#mla #show_zone #text_zone' ).attr('title','');
		$( '#mla #show_zone #text_zone').html('');
	},

	// обработка клика на одной записи 
	click_one( one ){
		let x = '',
			t = this;
		t.cl( 'click_one:: полученный запрос ' + one );		t.cl( t );
		x = t.X[one];		// взяли данные персоны
		t.show_one( x );	// передали оформлять
	},

	//  getting получение и обработка ответа сервера
	getting( X_bD ){
		t = this;
		t.cl( 'getting:: полученный результат [ X ]' );  t.cl( X_bD )
		if( typeof( X_bD ) != "object" ) {			//  проверяем - получен ли значимый ответ ???
			t.cl( 'Ошибка: ответ сервера не является объектом!' ); 	//	ой! - ответ не объект!
			t.ShowLoad( -1 );
			alert( 'Ошибка: ответ сервера не является объектом!' ); //	ой! - ответ не объект!
		} else {
			t.X_page = 1;								 // возврат на первую страницу
			t.X_length = X_bD.it.length ; 				 //	"выношу" длинну ответа в общее пространство
			t.cl( 'найдено всего: ' + t.X_length ); 	 //	тестовая печать в консоль
			t.cl( 'getting::' ); 	t.cl( X_bD.result ); //	тестовая печать в консоль
			t.X_bD = X_bD;								 // "выношу" весь ответ в общее пространство
			t.X = X_bD.result;							 // "выношу" целевой результат в общее пространство
			t.decorate( );								 // передача процесса на оформление
			t.ShowLoad( -1 );							 //
			return  X_bD.result;
		};
	},	//  getting получение и обработка ответа сервера


	//  запрос данных с сервера
	query( param = '' ){
		t = this;
		t.ShowLoad(1);				// заставка на экран на время получения результата
		let Url = '';
		if ( param ) { 				// если задан параметр к запросу - подключаем его
			param = '?' + param 
		}; 
		Url =  t.URL + param  ; 
		t.cl ( ' query: ' + Url );	
		$.getJSON( Url, function( json ) { t.getting( json, param ) ;});	//  обращение к серверу
	},

// шаблон оформления информации в общем выводе 
		templ_all:  '<div class="allone" title ="'
		+'flag -&gt; [#flag#],\n '
		+'int_id -&gt; #int_id#,\n '
		+'address -&gt; #address#\n '
		+'" id = "#N#" >'
		+'<div class="created"> #created# </div>'
		+'<div class="str">#str# </div>'
		+'<div class="flag">#flag# </div>'
		+'<div class="int_id">#int_id# </div>'
		+'<div class="address">#address# </div>'
		+'</div>',

// шаблон оформления информации в частном выводе
		templ_one:  '<button class="close" ><span>✖</span></button>'
		+'<div class="oneone" >'
		+'<div class="created"> #created# </div>'
		+'<div class="flag"><span>флаг сообщения:</span> [#flag#]</div>'
		+'<div class="int_id"><span>int_id:</span> #int_id# </div>'
		+'<div class="address"><span>email:</span> #address# </div>'
		+'<div class="str"><span>Дополнительная информация:</span><br>#str# </div>'
		+'</div>'

/* */

};

function query(){
//	MLA.query();
	$('#mla input.find').focus();
}