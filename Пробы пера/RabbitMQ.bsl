// проба использования библиотеки: https://sbpg.atlassian.net/wiki/spaces/1C2RMQ/overview
//

#Область ВзаимодействиеСRabbitMQ

Функция ПараметрыПодключенияAMQP()
	
	параметры = новый Структура;
	параметры.Вставить("HostName");
	параметры.Вставить("UserName");
	параметры.Вставить("Password");
	параметры.Вставить("Port");
	параметры.Вставить("VirtualHost");
	возврат параметры;
	
КонецФункции

Функция ПараметрыПодключенияAMQPПоУмолчанию()
	
	параметры = новый Структура;
	параметры.Вставить("HostName",    "192.168.0.1");
	параметры.Вставить("UserName",    "");
	параметры.Вставить("Password",    "");
	параметры.Вставить("Port",        "");
	параметры.Вставить("VirtualHost", "");
	Возврат параметры;
	
КонецФункции

Функция ПараметрыОбменаБезОчереди()
	
	ПараметрыОбмена = Новый Структура;
	ПараметрыОбмена.Вставить("ИмяОбмена");
	ПараметрыОбмена.Вставить("ИмяМаршрута");
	Возврат ПараметрыОбмена;
	
КонецФункции

Функция ПараметрыОбменаСОчередью()
	
	ПараметрыОбмена = Новый Структура;
	ПараметрыОбмена.Вставить("ИмяОбмена");
	ПараметрыОбмена.Вставить("ИмяМаршрута");
	ПараметрыОбмена.Вставить("ИмяОчереди");
	Возврат ПараметрыОбмена;
	
КонецФункции

Функция ИменаМаршрутов()
	
	имена = новый Структура;
	имена.Вставить("Розница", "Roznica");
	Возврат имена;
	
КонецФункции


Функция ИмяОбмена()
	
	Возврат "test";
	
КонецФункции

Функция ИмяОтправителя()

	возврат "testSend";
	
КонецФункции // ИмяОтправителя()

Функция ИдентификаторСообщения()

	Возврат Строка(Новый УникальныйИдентификатор);

КонецФункции // ИдентификаторСообщения()


Функция ПодключитьсяКФабрикеAMQP()
	
	Попытка
		ФабрикаAMQP = Новый COMОбъект("RabbitMQ.Client.ConnectionFactory");
	Исключение
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		ЗаписьЖурналаРегистрации("RabbitMQ: подключение к фабрике",
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные().ПолноеИмя(),
			,
			ТекстОшибки);
		ФабрикаAMQP = Неопределено;
	КонецПопытки;
	возврат ФабрикаAMQP;
	
КонецФункции

Функция ОткрытьСоединениеRabbitMQ(параметры)
	
	ФабрикаAMQP = ПодключитьсяКФабрикеAMQP();
	если ФабрикаAMQP = Неопределено тогда
		возврат Неопределено;
	КонецЕсли;
	ЗаполнитьЗначенияСвойств(ФабрикаAMQP, параметры);
	Попытка
		соединение = ФабрикаAMQP.CreateConnection();
	Исключение
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		ЗаписьЖурналаРегистрации("RabbitMQ: создание соединения (CreateConnection)",
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные().ПолноеИмя(),
			,
			ТекстОшибки);
		соединение = Неопределено;
	КонецПопытки;
	возврат соединение;
	
КонецФункции

Функция ОбменВRabbitMQНеСуществует(Модель, ИмяОбмена)
	
	Отказ = Ложь;
	Попытка
		Модель.ExchangeDeclarePassive(ИмяОбмена);
	Исключение
		Отказ = Истина;
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		Заголовок = СтрШаблон("RabbitMQ: имя обмен %1 не существует", ИмяОбмена);
		ЗаписьЖурналаРегистрации(Заголовок,
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные().ПолноеИмя(),
			,
			ТекстОшибки);
	КонецПопытки;
	возврат Отказ;
	
КонецФункции

Функция ОчередьВRabbitMQНеСуществует(Модель, ИмяОчереди)
	
	Отказ = Ложь;
	Попытка
		Модель.QueueDeclarePassive(ИмяОчереди);
	Исключение
		Отказ = Истина;
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		Заголовок = СтрШаблон("RabbitMQ: очередь %1 не существует", ИмяОчереди);
		ЗаписьЖурналаРегистрации(Заголовок,
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные().ПолноеИмя(),
			,
			ТекстОшибки);
	КонецПопытки;  
	возврат Отказ;
	
КонецФункции

Функция ВыполнитьКомандуBasicPublish(модель, ПараметрыОбмена, параметрыОтправки, СтрокаSafeArray)
	
	Попытка
		модель.BasicPublish(
			ПараметрыОбмена.ИмяОбмена, 
			ПараметрыОбмена.ИмяМаршрута, 
			False, 
			ПараметрыОтправки, 
			СтрокаSafeArray);
		Успех = Истина;
	Исключение
		Успех = Ложь;
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		ЗаписьЖурналаРегистрации("RabbitMQ: отправка сообщения (BasicPublish)",
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные().ПолноеИмя(),
			,
			ТекстОшибки);
	КонецПопытки;
	
	Возврат Успех;
	
КонецФункции

Процедура ЗакрытьСодединениеСRabbitMQ(Модель, Соединение)
	
	Модель.Close();
	Соединение.Close();
	
КонецПроцедуры


Функция ПодготовитьСообщениеКОтправке(СообщениеДляОтправки)

	Кодировка = КодировкаТекста.UTF8;
	ПотокВПамяти = ПолучитьДвоичныеДанныеИзСтроки(СообщениеДляОтправки, Кодировка).ОткрытьПотокДляЧтения();
	ЧтениеДанных = Новый ЧтениеДанных(ПотокВПамяти, Кодировка);
	СтрокаSafeArray = Новый COMSafeArray("VT_UI1", ПотокВПамяти.Размер());
	Пока ПотокВПамяти.ТекущаяПозиция() < ПотокВПамяти.Размер() Цикл
		Позиция = ПотокВПамяти.ТекущаяПозиция();
		СтрокаSafeArray.SetValue(Позиция, ЧтениеДанных.ПрочитатьБайт());
	КонецЦикла;
	ЧтениеДанных.Закрыть();
	ПотокВПамяти.Закрыть();
	Возврат СтрокаSafeArray;

КонецФункции // ПодготовитьСообщениеКОтправке()

Функция ПараметрыОтправкиПоУмолчанию()

	параметры = Новый Структура;
	параметры.Вставить("AppId", ИмяОтправителя());
	параметры.Вставить("ContentType", "application/json");  // тип передоваемых данных // text/plain application/json  
	параметры.Вставить("DeliveryMode", МетодыХранения().ХранитьНаДиске);
	параметры.Вставить("CorrelationId", ИдентификаторСообщения());
	возврат параметры;
	
КонецФункции // ПараметрыОтправкиПоУмолчанию()

Функция МетодыХранения()

	параметры = Новый Структура;
	параметры.Вставить("ХранитьВОЗУ", 1);
	параметры.Вставить("ХранитьНаДиске", 2);
	возврат параметры;
	
КонецФункции // МетодыХранения()


Функция ОтправитьВRabbitMQ(ИмяМаршрута, СообщениеДляОтправки) Экспорт
	
	параметры = ПараметрыПодключенияAMQP();
	ЗаполнитьЗначенияСвойств(параметры, ПараметрыПодключенияAMQPПоУмолчанию());
	соединение = ОткрытьСоединениеRabbitMQ(параметры);
	если соединение = Неопределено тогда
		возврат Ложь;
	КонецЕсли;
	модель = Соединение.CreateModel();
	параметрыОбмена = ПараметрыОбменаБезОчереди();
	параметрыОбмена.ИмяОбмена   = ИмяОбмена();
	параметрыОбмена.ИмяМаршрута = ИмяМаршрута;
	Если ОбменВRabbitMQНеСуществует(модель, параметрыОбмена.ИмяОбмена) Тогда
		ЗакрытьСодединениеСRabbitMQ(модель, соединение);
		Возврат Ложь;
	КонецЕсли;
	
	строкаSafeArray   = ПодготовитьСообщениеКОтправке(СообщениеДляОтправки);
	параметрыОтправки = модель.CreateBasicProperties();
	ЗаполнитьЗначенияСвойств(параметрыОтправки, ПараметрыОтправкиПоУмолчанию());
	Успех = ВыполнитьКомандуBasicPublish(модель, ПараметрыОбмена, параметрыОтправки, СтрокаSafeArray);
	ЗакрытьСодединениеСRabbitMQ(модель, соединение);
	Возврат Успех;
	
КонецФункции

Функция ОтправитьВОчередьRabbitMQ(ИмяМаршрута, ИмяОчереди, СообщениеДляОтправки) Экспорт
	
	параметры = ПараметрыПодключенияAMQP();
	ЗаполнитьЗначенияСвойств(параметры, ПараметрыПодключенияAMQPПоУмолчанию());
	соединение = ОткрытьСоединениеRabbitMQ(параметры);
	если соединение = Неопределено тогда
		возврат Ложь;
	КонецЕсли;
	модель = Соединение.CreateModel();
	параметрыОбмена = ПараметрыОбменаСОчередью();
	параметрыОбмена.ИмяОбмена   = ИмяОбмена();
	параметрыОбмена.ИмяМаршрута = ИмяМаршрута;
	параметрыОбмена.ИмяОчереди  = ИмяОчереди;
	Если ОбменВRabbitMQНеСуществует(модель, параметрыОбмена.ИмяОбмена) Тогда
		ЗакрытьСодединениеСRabbitMQ(модель, соединение);
		возврат Ложь;
	КонецЕсли;
	Если ОчередьВRabbitMQНеСуществует(модель, параметрыОбмена.ИмяОчереди) Тогда
		ЗакрытьСодединениеСRabbitMQ(модель, соединение);
		возврат Ложь;
	КонецЕсли;
	строкаSafeArray   = ПодготовитьСообщениеКОтправке(СообщениеДляОтправки);
	параметрыОтправки = модель.CreateBasicProperties();
	ЗаполнитьЗначенияСвойств(параметрыОтправки, ПараметрыОтправкиПоУмолчанию());
	Успех = ВыполнитьКомандуBasicPublish(модель, ПараметрыОбмена, параметрыОтправки, СтрокаSafeArray);
	ЗакрытьСодединениеСRabbitMQ(модель, соединение);
	Возврат Успех;
	
КонецФункции


Процедура ТестДолжен_ОтправитьПустоеСообщениеВРэббит() Экспорт
	
	Успех = ОтправитьВRabbitMQ(ИменаМаршрутов().Розница, СформироватьJSON(Новый Структура));
	Утверждения.проверить(Успех, "обмен с рэббит завершился ошибкой");
	
КонецПроцедуры

 
// преборазует входящую структуру в JSON
// экранирует не ASCII символы, для отключения поправить параметры записи
//
// ПАРАМЕТРЫ:
// ВходящиеДанные - Структура
//	Ключ - строка
//	Значение - Строка, Число, Дата, Булево, Массив, Структура -
// 		любое серилизуемое в JSON значение
// ФорматироватьJSON - БУЛЕВО - если нужно сформировать JSON для вывода в форматированном виде
//
// Возвращаемое значение:
// 	Строка - сформированный JSON
//
Функция СформироватьJSON(ВходящиеДанные, ФорматироватьJSON = Ложь)
	
	Если ФорматироватьJSON Тогда
		СимволФорматирования = Символы.Таб;
	Иначе
		СимволФорматирования = Неопределено;	
	КонецЕсли;
	
	ПараметрыЗаписиJSON = Новый ПараметрыЗаписиJSON(,СимволФорматирования,, ЭкранированиеСимволовJSON.СимволыВнеASCII);
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.ПроверятьСтруктуру = Ложь;
	ЗаписьJSON.УстановитьСтроку(ПараметрыЗаписиJSON);
	ЗаписатьJSON(ЗаписьJSON, ВходящиеДанные);
	
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции // СформироватьJSON()

#КонецОбласти

