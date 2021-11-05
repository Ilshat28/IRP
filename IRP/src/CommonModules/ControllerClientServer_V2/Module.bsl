
// CONTROLLER
// 
// ОБЩИЙ МОДУЛЬ ДЛЯ SalesInvoice и всех кто с него скопирован - уровень Данные (линковка бизнес логики со структурой документа)
// никаких запросов к БД и расчетов тут делать нельзя, модифицировать форму задавать вопросы пользователю и т.д нельзя 
// только чтение из объекта и запись в объект

Procedure EnableChainLinks(EntryPointName, Parameters, Chain) Export
	RouteEnableChainLinks(EntryPointName, Parameters, Chain);
EndProcedure

Procedure RouteEnableChainLinks(EntryPointName, Parameters, Chain)
	   If EntryPointName = "CompanyEntryPoint"      Then CompanyEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "PartnerEntryPoint"      Then PartnerEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "LegalNameEntryPoint"    Then LegalNameEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "AgreementEntryPoint"    Then AgreementEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "PriceTypeEntryPoint"    Then PriceTypeEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "PriceEntryPoint"        Then PriceEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "NetAmountEntryPoint"    Then NetAmountEntryPointEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "TaxAmountEntryPoint"    Then TaxAmountEntryPointEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "OffersAmountEntryPoint" Then OffersAmountEntryPointEnableChainLinks(Parameters, Chain);
	ElsIf EntryPointName = "TotalAmountEntryPoint"  Then TotalAmountEntryPointEnableChainLinks(Parameters, Chain);
	Else Raise StrTemplate("Route enable chain links error [%1]", EntryPointName); EndIf;
EndProcedure

#Region PARTNER

// Client Event handler, вызывается из модуля ViewClient_V2
Procedure PartnerOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("PartnerEntryPoint", Parameters);
EndProcedure

Procedure PartnerEnableChainLinks(Parameters, Chain)
	// При изменении партнера нужно изменить LegalName
	Chain.LegalName.Enable = True;
	Chain.LegalName.Setter = "SetLegalName";
	// эти данные (параметры) нужны для получения LegalName
	LegalNameOptions = ModelClientServer_V2.LegalNameOptions();
	LegalNameOptions.Partner   = GetProperty(Parameters, "Partner");
	LegalNameOptions.LegalName = GetProperty(Parameters, "LegalName");;
	Chain.LegalName.Options.Add(LegalNameOptions);
	
	// При изменении партнера нужно изменить Agreement
	Chain.Agreement.Enable = True;
	Chain.Agreement.Setter = "SetAgreement"
	;
	// эти данные (параметры) нужны для получения Agreement
	AgreementOptions = ModelClientServer_V2.AgreementOptions();
	AgreementOptions.Partner       = GetProperty(Parameters, "Partner");
	AgreementOptions.Agreement     = GetProperty(Parameters, "Agreement");
	AgreementOptions.CurrentDate   = GetProperty(Parameters, "Date");
	AgreementOptions.AgreementType = PredefinedValue("Enum.AgreementTypes.Customer");
	Chain.Agreement.Options.Add(AgreementOptions);
EndProcedure

Procedure SetPartner_API(Parameters, Results) Export
	ModelClientServer_V2.Init_API("PartnerEntryPoint", Parameters);
	SetPartner(Parameters, Results);
EndProcedure

Procedure SetPartner(Parameters, Results) Export
	Setter("PartnerEntryPoint", "Partner", Parameters, Results);
EndProcedure

#EndRegion

#Region LEGAL_NAME

// Client Event handler вызывается из модуля ViewClient_V2
Procedure LegalNameOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("LegalNameEntryPoint", Parameters);
EndProcedure

Procedure LegalNameEnableChainLinks(Parameters, Chain)
	Return;
EndProcedure

Procedure SetLegalName(Parameters, Results) Export
	Setter("LegalNameEntryPoint", "LegalName", Parameters, Results, "OnSetLegalName");
EndProcedure

#EndRegion

#Region AGREEMENT

// Client Event handler вызывается из модуля ViewClient_V2
Procedure AgreementOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("AgreementEntryPoint", Parameters);
EndProcedure

Procedure AgreementEnableChainLinks(Parameters, Chain) Export
	// При изменении Agreement нужно изменить Company
	Chain.Company.Enable = True;
	Chain.Company.Setter =  "SetCompany";
	
	// Эти данные (параметры) нужны для получения Company
	CompanyOptions = ModelClientServer_V2.CompanyOptions();
	CompanyOptions.Agreement = GetProperty(Parameters, "Agreement");
	CompanyOptions.Company   = GetProperty(Parameters, "Company");
	
	Chain.Company.Options.Add(CompanyOptions);
	
	// При изменении Agreement нужно изменить PriceType
	Chain.PriceType.Enable = True;
	Chain.PriceType.Setter = "SetPriceType";
	
	// Эти данные (параметры) нужны для получения PriceType
	// PriceType находится в табличной части ItemList, така как это уровень данных то беремиз этой табличной части
	For Each Row In Parameters.Object.ItemList Do
		PriceTypeOptions = ModelClientServer_V2.PriceTypeOptions();
		PriceTypeOptions.Agreement = GetProperty(Parameters, "Agreement");
		// ключ нужен что бы потом, когда вернутся результаты из модуля Model идентифицировать строку,
		// для реквизитов в шапке ключ можно не заполнять, шапка только одна
		PriceTypeOptions.Key = Row.Key;
		Chain.PriceType.Options.Add(PriceTypeOptions);
	EndDo;
EndProcedure

Procedure SetAgreement(Parameters, Results) Export
	Setter("AgreementEntryPoint", "Agreement", Parameters, Results);
EndProcedure

#EndRegion

#Region COMPANY

Procedure CompanyEnableChainLinks(Parameters, Chain) Export
	Return;
EndProcedure

Procedure SetCompany(Parameters, Results) Export
	Setter("CompanyEntryPoint", "Company", Parameters, Results);
EndProcedure

#EndRegion

#Region ITEM_LIST_PRICE_TYPE

Procedure ItemListPriceTypeOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("PriceTypeEntryPoint", Parameters);
EndProcedure

Procedure PriceTypeEnableChainLinks(Parameters, Chain) Export
	Chain.Price.Enable = True;
	Chain.Price.Setter = "SetPrice";
	
	Rows = Parameters.Object.ItemList;
	If Parameters.Property("Rows") Then
		// расчет только для конкретных строк, переданных в параметре
		Rows = Parameters.Rows;
	EndIf;
	For Each Row In Rows Do
		PriceOptions = ModelClientServer_V2.PriceOptions();
		PriceOptions.Ref        = Parameters.Object.Ref;
		PriceOptions.Date       = GetProperty(Parameters, "Date");
		PriceOptions.PriceType  = GetProperty(Parameters, "ItemList.PriceType", Row.Key);
		PriceOptions.ItemKey    = GetProperty(Parameters, "ItemList.ItemKey"  , Row.Key);
		PriceOptions.Unit       = GetProperty(Parameters, "ItemList.Unit"     , Row.Key);
		PriceOptions.Key        = Row.Key;
		Chain.Price.Options.Add(PriceOptions);
	EndDo;
EndProcedure

// Устанавливает PriceType в табличную часть ItemList
Procedure SetPriceType(Parameters, Results) Export
	Setter("PriceTypeEntryPoint", "ItemList.PriceType", Parameters, Results);
EndProcedure

#EndRegion

#Region ITEM_LIST_PRICE

Procedure ItemListPriceOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("PriceEntryPoint", Parameters);
EndProcedure

Procedure PriceEnableChainLinks(Parameters, Chain) Export
	Chain.Calculations.Enable = True;
	Chain.Calculations.Setter = "SetCalculations";
	
	Rows = Parameters.Object.ItemList;
	If Parameters.Property("Rows") Then
		// расчет только для конкретных строк, переданных в параметре
		Rows = Parameters.Rows;
	EndIf;
	For Each Row In Rows Do
		// при изменении цены нужно пересчитать NetAmount, TotalAmount, TaxAmount, OffersAmount
		CalculationsOptions = ModelClientServer_V2.CalculationsOptions();
		
		CalculationsOptions.CalculateNetAmount.Enable   = True;
		CalculationsOptions.CalculateTotalAmount.Enable = True;
		CalculationsOptions.CalculateTaxAmount.Enable   = False; // расчет налогов еще не написан
		
		CalculationsOptions.AmountOptions.DontCalculateRow = GetProperty(Parameters, "ItemList.DontCalculateRow", Row.Key);
		
		CalculationsOptions.AmountOptions.NetAmount        = GetProperty(Parameters, "ItemList.NetAmount"    , Row.Key);
		CalculationsOptions.AmountOptions.OffersAmount     = GetProperty(Parameters, "ItemList.OffersAmount" , Row.Key);
		CalculationsOptions.AmountOptions.TaxAmount        = GetProperty(Parameters, "ItemList.TaxAmount"    , Row.Key);
		CalculationsOptions.AmountOptions.TotalAmount      = GetProperty(Parameters, "ItemList.TotalAmount"  , Row.Key);
		
		CalculationsOptions.PriceOptions.Price              = GetProperty(Parameters, "ItemList.Price"              , Row.Key);
		CalculationsOptions.PriceOptions.PriceType          = GetProperty(Parameters, "ItemList.PriceType"          , Row.Key);
		CalculationsOptions.PriceOptions.Quantity           = GetProperty(Parameters, "ItemList.Quantity"           , Row.Key);
		CalculationsOptions.PriceOptions.QuantityInBaseUnit = GetProperty(Parameters, "ItemList.QuantityInBaseUnit" , Row.Key);
		
		CalculationsOptions.TaxOptions.PriceIncludeTax  = GetProperty(Parameters, "PriceIncludeTax", Row.Key);
		
		CalculationsOptions.Key = Row.Key;
		
		Chain.Calculations.Options.Add(CalculationsOptions);
	EndDo;
EndProcedure

Procedure SetPrice(Parameters, Results) Export
	Setter("PriceEntryPoint", "ItemList.Price", Parameters, Results);
EndProcedure

#EndRegion

#Region NET_OFFERS_TAX_TOTAL_AMOUNTS

Procedure ItemListNetAmountOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("NetAmountEntryPoint", Parameters);
EndProcedure

Procedure NetAmountEntryPointEnableChainLinks(Parameters, Chain)
	Return;
EndProcedure

Procedure ItemListTaxAmountOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("TaxAmountEntryPoint", Parameters);
EndProcedure

Procedure TaxAmountEntryPointEnableChainLinks(Parameters, Chain)
	Return;
EndProcedure

Procedure ItemListOffersAmountOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("OffersAmountEntryPoint", Parameters);
EndProcedure

Procedure OffersAmountEntryPointEnableChainLinks(Parameters, Chain)
	Return;
EndProcedure

Procedure ItemListTotalAmountOnChange(Parameters) Export
	ModelClientServer_V2.EntryPoint("TotalAmountEntryPoint", Parameters);
EndProcedure

Procedure TotalAmountEntryPointEnableChainLinks(Parameters, Chain)
	Return;
EndProcedure

Procedure SetCalculations(Parameters, Results) Export
	Setter("NetAmountEntryPoint"   , "ItemList.NetAmount"   , Parameters, Results, , "NetAmount");
	Setter("TaxAmountEntryPoint"   , "ItemList.TaxAmount"   , Parameters, Results, , "TaxAmount");
	Setter("OffersAmountEntryPoint", "ItemList.OffersAmount", Parameters, Results, , "OffersAmount");
	Setter("TotalAmountEntryPoint" , "ItemList.TotalAmount" , Parameters, Results, , "TotalAmount");
EndProcedure

#EndRegion

// Вызывается когда вся цепочка связанных действий будет заверщена
Procedure OnChainComplete(Parameters) Export
	#IF Client THEN
		// на клиенте возможно нужно задать вопрос пользователю, поэтому сразу из кэша в объект не переносим
		If Parameters.ViewModule <> Undefined Then
			Parameters.ViewModule.OnChainComplete(Parameters);
		EndIf;
	#ENDIF
	
	#IF Server THEN
		// на сервере спрашивать некого, сразу переносим из кэша в объект
		CommitChainChanges(Parameters);
	#ENDIF
EndProcedure

// Переносит изменения из Cache в Object
Procedure CommitChainChanges(Parameters) Export
	For Each Property In Parameters.Cache Do
		If TypeOf(Property.Value) = Type("Array") Then // это табличная часть
			For Each Row In Property.Value Do
				FillPropertyValues(Parameters.Object[Property.Key].FindRows(New Structure("Key", Row.Key))[0], Row);
			EndDo;
		Else
			Parameters.Object[Property.Key] = Property.Value; // это реквизит шапки
		EndIf;
	EndDo;
	#IF Client THEN
		If Parameters.ViewNotify.Count() And Parameters.ViewModule = Undefined Then
			Raise "View module undefined";
		EndIf;
		For Each ViewNotify In Parameters.ViewNotify Do
			Execute StrTemplate("%1.%2(Parameters);", Parameters.ViewModuleName, ViewNotify);
		EndDo;
	#ENDIF
EndProcedure

Procedure Setter(EntryPointName, DataPath, Parameters, Results, ViewNotify = Undefined, ValueDataPath = Undefined)
	IsChanged = False;
	For Each Result In Results Do
		_Key   = Result.Options.Key;
		If ValueIsFilled(ValueDataPath) Then
			_Value = Result.Value[ValueDataPath];
		Else
			_Value = Result.Value;
		EndIf;
		If SetProperty(Parameters, DataPath, _Key, _Value) Then
			IsChanged = True;
		EndIf;
	EndDo;
	If IsChanged Then
		If ViewNotify <> Undefined Then
			// переадресация в клиентский модуль, вызов был с клиента, на форме что то надо обновить
			// вызывать будем потом когда завершится вся цепочка действий, и изменения будут перенесены с кэша в объект
			Parameters.ViewNotify.Add(ViewNotify);
		EndIf;
		ModelClientServer_V2.EntryPoint(EntryPointName, Parameters);
	EndIf;
EndProcedure

// параметр Key используется когда DataPath указывает на реквизит табличной части, например ItemList.PriceType
Function GetProperty(Parameters, DataPath, Key = Undefined)
	Segments = StrSplit(DataPath, ".");
	If Segments.Count() = 1 Then // это реквизит шапки, он указывается без точки, например Company
		If Parameters.Cache.Property(DataPath) Then
			Return Parameters.Cache[DataPath];
		Else
			Return Parameters.Object[DataPath];
		EndIf;
	ElsIf Segments.Count() = 2 Then // это реквизит табличной части, состоит из двух частей разделенных точкой ItemList.PriceType
		TableName = Segments[0];
		ColumnName = Segments[1];
		
		RowByKey = Undefined;
		If Parameters.Cache.Property(TableName) Then
			For Each Row In Parameters.Cache[TableName] Do
				If Not Row.Property(ColumnName) Then
					Continue;
				EndIf;
				If Row.Key = Key Then
					RowByKey = Row;
				EndIf;
			EndDo;
		EndIf;
		If RowByKey = Undefined Then
			RowByKey = Parameters.Object[TableName].FindRows(New Structure("Key", Key))[0];
		EndIf;
		Return RowByKey[ColumnName];
	Else
		// реквизитов с таким путем не бывает
		Raise StrTemplate("Wrong data path [%1]", DataPath);
	EndIf;
EndFunction

// Устанавливает свойства по переданному DataPath, например ItemList.PriceType или Company
// возвращает True если хотябы одно свойство было изменено
Function SetProperty(Parameters, DataPath, _Key, _Value)
	// что бы получить значение из коллекции нужно искать его по ключу
	If GetProperty(Parameters, DataPath, _Key) = _Value Then
		Return False; // Свойство не изменилось
	EndIf;
	// измененные свойства сохраняются в кэш
	Segments = StrSplit(DataPath, ".");
	If Segments.Count() = 1 Then // это реквизит шапки, он указывается без точки, например Company
		Parameters.Cache.Insert(DataPath, _Value);
	ElsIf Segments.Count() = 2 Then // это реквизит табличной части, состоит из двух частей разделенных точкой ItemList.PriceType
		TableName = Segments[0];
		ColumnName = Segments[1];
		If Not Parameters.Cache.Property(TableName) Then
			Parameters.Cache.Insert(TableName, New Array());
		EndIf;
		IsRowExists = False;
		For Each Row In Parameters.Cache[TableName] Do
			If Row.Key = _Key Then
				Row.Insert(ColumnName, _Value);
				IsRowExists = True;
				Break;
			EndIf;
		EndDo;
		If Not IsRowExists Then
			NewRow = New Structure();
			NewRow.Insert("Key"      , _Key);
			NewRow.Insert(ColumnName , _Value);
			Parameters.Cache[TableName].Add(NewRow);
		EndIf;
	Else
		// реквизитов с таким путем не бывает
		Raise StrTemplate("Wrong data path [%1]", DataPath);
	EndIf;	
	Return True;
EndFunction


