// @deprecated
//#Region Service
//Function GetLockFields(Data) Export
//	Result = New Structure();
//	Result.Insert("RegisterName", "AccumulationRegister.R1012B_PurchaseOrdersInvoiceClosing");
//	LockInfo = New Structure("Data, Fields", Data, PostingServer.GetLockFieldsMap(GetLockFieldNames()));
//	Result.Insert("LockInfo", LockInfo);
//	Return Result;
//EndFunction
//
//Function GetLockFieldNames() Export
//	Return "";
//EndFunction
//
//Function GetExistsRecords(Ref, RecordType = Undefined, AddInfo = Undefined) Export
//	Return PostingServer.GetExistsRecordsFromAccRegister(Ref,
//		"AccumulationRegister.R1012B_PurchaseOrdersInvoiceClosing", RecordType, AddInfo);
//EndFunction
//#EndRegion