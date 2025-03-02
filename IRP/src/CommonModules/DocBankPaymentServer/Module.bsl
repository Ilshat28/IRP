#Region FormEvents

Procedure OnCreateAtServer(Object, Form, Cancel, StandardProcessing) Export
	MoneyDocumentsServer.OnCreateAtServer(Object, Form, Cancel, StandardProcessing);
EndProcedure

Procedure OnReadAtServer(Object, Form, CurrentObject) Export
	MoneyDocumentsServer.OnReadAtServer(Object, Form, CurrentObject);
EndProcedure

Procedure AfterWriteAtServer(Object, Form, CurrentObject, WriteParameters) Export
	MoneyDocumentsServer.AfterWriteAtServer(Object, Form, CurrentObject, WriteParameters);
EndProcedure

#EndRegion

Function GetDocumentTable_CashTransferOrder(ArrayOfBasisDocuments, EndOfDate = Undefined) Export
	TempTableManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTableManager;
	Query.Text = GetDocumentTable_CashTransferOrder_QueryText();
	Query.SetParameter("ArrayOfBasisDocuments", ArrayOfBasisDocuments);
	Query.SetParameter("UseArrayOfBasisDocuments", True);
	If EndOfDate = Undefined Then
		Query.SetParameter("EndOfDate", CurrentDate());
	Else
		Query.SetParameter("EndOfDate", EndOfDate);
	EndIf;

	Query.Execute();
	Query.Text =
	"SELECT
	|	tmp.BasedOn AS BasedOn,
	|	tmp.TransactionType AS TransactionType,
	|	tmp.Company AS Company,
	|	tmp.Branch AS Branch,
	|	tmp.FinancialMovementType AS FinancialMovementType,
	|	tmp.Account AS Account,
	|	tmp.TransitAccount AS TransitAccount,
	|	tmp.Currency AS Currency,
	|	tmp.Amount AS Amount,
	|	tmp.PlaningTransactionBasis AS PlaningTransactionBasis
	|FROM
	|	tmp_CashTransferOrder AS tmp";
	QueryResult = Query.Execute();
	Return QueryResult.Unload();
EndFunction

Function GetDocumentTable_CashTransferOrder_QueryText() Export
	Return "SELECT ALLOWED
		   |	""CashTransferOrder"" AS BasedOn,
		   |	CASE
		   |		WHEN Doc.SendCurrency = Doc.ReceiveCurrency
		   |			THEN VALUE(Enum.OutgoingPaymentTransactionTypes.CashTransferOrder)
		   |		ELSE VALUE(Enum.OutgoingPaymentTransactionTypes.CurrencyExchange)
		   |	END AS TransactionType,
		   |	R3035T_CashPlanningTurnovers.FinancialMovementType AS FinancialMovementType,
		   |	R3035T_CashPlanningTurnovers.Company AS Company,
		   |	R3035T_CashPlanningTurnovers.Branch AS Branch,
		   |	R3035T_CashPlanningTurnovers.Account AS Account,
		   |	R3035T_CashPlanningTurnovers.Account.TransitAccount AS TransitAccount,
		   |	R3035T_CashPlanningTurnovers.Currency AS Currency,
		   |	R3035T_CashPlanningTurnovers.AmountTurnover AS Amount,
		   |	R3035T_CashPlanningTurnovers.BasisDocument AS PlaningTransactionBasis
		   |INTO tmp_CashTransferOrder
		   |FROM
		   |	AccumulationRegister.R3035T_CashPlanning.Turnovers(, &EndOfDate, ,
		   |		CashFlowDirection = VALUE(Enum.CashFlowDirections.Outgoing)
		   |	AND CurrencyMovementType = VALUE(ChartOfCharacteristicTypes.CurrencyMovementType.SettlementCurrency)
		   |	AND CASE
		   |		WHEN &UseArrayOfBasisDocuments
		   |			THEN BasisDocument IN (&ArrayOfBasisDocuments)
		   |		ELSE TRUE
		   |	END) AS R3035T_CashPlanningTurnovers
		   |		INNER JOIN Document.CashTransferOrder AS Doc
		   |		ON R3035T_CashPlanningTurnovers.BasisDocument = Doc.Ref
		   |WHERE
		   |	R3035T_CashPlanningTurnovers.Account.Type = VALUE(Enum.CashAccountTypes.Bank)
		   |	AND R3035T_CashPlanningTurnovers.AmountTurnover > 0";
EndFunction

Function GetDocumentTable_CashTransferOrder_ForClient(ArrayOfBasisDocuments, ObjectRef = Undefined) Export
	EndOfDate = Undefined;
	If ValueIsFilled(ObjectRef) Then
		EndOfDate = New Boundary(ObjectRef.PointInTime(), BoundaryType.Excluding);
	EndIf;
	ArrayOfResults = New Array();
	ValueTable = GetDocumentTable_CashTransferOrder(ArrayOfBasisDocuments, EndOfDate);
	For Each Row In ValueTable Do
		NewRow = New Structure();
		NewRow.Insert("BasedOn"                 , Row.BasedOn);
		NewRow.Insert("TransactionType"         , Row.TransactionType);
		NewRow.Insert("Company"                 , Row.Company);
		NewRow.Insert("Branch"                  , Row.Branch);
		NewRow.Insert("Account"                 , Row.Account);
		NewRow.Insert("TransitAccount"          , Row.TransitAccount);
		NewRow.Insert("Currency"                , Row.Currency);
		NewRow.Insert("Amount"                  , Row.Amount);
		NewRow.Insert("PlaningTransactionBasis" , Row.PlaningTransactionBasis);
		ArrayOfResults.Add(NewRow);
	EndDo;
	Return ArrayOfResults;
EndFunction

#Region ListFormEvents

Procedure OnCreateAtServerListForm(Form, Cancel, StandardProcessing) Export
	DocumentsServer.OnCreateAtServerListForm(Form, Cancel, StandardProcessing);
EndProcedure

#EndRegion

#Region ChoiceFormEvents

Procedure OnCreateAtServerChoiceForm(Form, Cancel, StandardProcessing) Export
	DocumentsServer.OnCreateAtServerChoiceForm(Form, Cancel, StandardProcessing);
EndProcedure

#EndRegion