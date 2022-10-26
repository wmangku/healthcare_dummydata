USE Healthcare_DB
 	/*
	Easy: Question 1
	How many rows of data are in the FactTable that include 
	a Gross Charge greater than $100?
	*/
	Select count(GrossCharge) as CountOfRows
	From FactTable
	where FactTable.GrossCharge > '100'

	Select * 
	from FactTable
	/*
	Easy: Question 2
	How many unique patients exist is the Healthcare_DB?
	*/
	select count(distinct PatientNumber) as UniquePatients
	from FactTable

	/*
	Easy: Question 3
	How many CptCodes are in each CptGrouping?
	*/
	Select 
		CptGrouping
		,count(distinct CptCode) as UniqueCptCode
	From dimCptCode
	Group by CptGrouping
	Order by UniqueCptCode desc


	Select *
	From dimCptCode
	/*
	Intermediate: Question 4
	How many physicians have submitted a Medicare insurance claim?
	*/
	Select
	PayerName
	,count(distinct ProviderNpi) as 'CountOfProviders'
	From
	FactTable
	INNER JOIN dimPhysician
		on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	INNER JOIN dimPayer
		on dimPayer.dimPayerPK = FactTable.dimPayerPK
	Group by PayerName
	--Where PayerName = 'Medicare'

	/*
	Intermediate: Question 5
	Calculate the Gross Collection Rate (GCR) for each
	LocationName - See Below 
	GCR = Payments divided GrossCharge
	Which LocationName has the highest GCR?
	*/
	
	Select
		distinct LocationName
		,-sum(Payment) / Sum(GrossCharge) as GCR
	From 
	FactTable
	INNER JOIN dimLocation
		on dimLocation.dimLocationPK = FactTable.dimLocationPK
	Group by 
		LocationName
	Order by
		GCR desc

	
	/*
	Intermediate: Question 6
	How many CptCodes have more than 100 units?
	*/

	Select
	Count(*) as 'CptCodesMoreThan100Units'
	From
	(Select
		CptCode
		,CptDesc
		,Sum(CptUnits) as 'Units'
	From
	FactTable
	INNER JOIN dimCptCode
		on dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
	Group by
		CptCode
		,CptDesc
	Having Sum(CptUnits) > '100') as a




	/*
	Intermediate: Question 7
	Find the physician specialty that has received the highest
	amount of payments. Then show the payments by month for 
	this group of physicians. 
	*/
	Select
		ProviderSpecialty
		,MonthPeriod
		,MonthYear
		,-Sum(Payment) as TotalPayment
	From
	FactTable
	INNER JOIN dimPhysician
		on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	INNER JOIN dimDate
		on dimDate.dimDatePostPK = FactTable.dimDatePostPK
	Where ProviderSpecialty = 'Internal Medicine'
	Group by
		ProviderSpecialty
		,MonthPeriod
		,MonthYear
	Order by 2 asc
		


	/*
	Intermediate: Question 8
	How many CptUnits by DiagnosisCodeGroup are assigned to 
	a "J code" Diagnosis (these are diagnosis codes with 
	the letter J in the code)?
	*/
	
	Select
		DiagnosisCodeGroup
		,Sum(CPTUnits) as TotalCPTUnits
	From
	FactTable
	INNER JOIN dimDiagnosisCode
		on dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
	Where DiagnosisCode like '%J%'
	Group by
		DiagnosisCodeGroup
		 
	Order by
		TotalCPTUnits Desc


	/*
	Easy: Question 9
	You've been asked to put together a report that details 
	Patient demographics. The report should group patients
	into three buckets- Under 18, between 18-65, & over 65
	Please include the following columns:
		-First and Last name in the same column
		-Email
		-Patient Age
		-City and State in the same column
	*/
	Select
		[FirstName] + ' ' + [LastName] as FullName
		,Email
		,PatientAge
		,Case	when PatientAge < 18 then 'Under 18'
				when PatientAge between 18 and 65 then '18-65'
				when patientage >= 65 then 'Over 65'
				Else null End as 'PatientAgeBucket'
		,[City] + ', ' + [State] as CityState
	From
	dimPatient
	Order by PatientAge asc

	/*
	Easy: Question 10
	How many dollars have been written off (adjustments) due to credentialing (AdjustmentReason)? 
	Which location has the highest number of credentialing adjustments? 
	How many physicians at this location have been impacted by credentialing adjustments? What does this mean?
	*/

	Select
		AdjustmentReason
		,LocationName
		,-Sum(Adjustment) as TotalAdjustment
		,Count(distinct ProviderName) as TotalProviders
	From
		FactTable
	INNER JOIN dimTransaction
		on dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
	INNER JOIN dimLocation
		on dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPhysician
		on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	Where 
		AdjustmentReason = 'Credentialing' 
	Group by 
		AdjustmentReason
		,LocationName
	Order by TotalAdjustment desc

	Select distinct
		ProviderNpi
		,ProviderName
	From
		FactTable
	INNER JOIN dimTransaction
		on dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
	INNER JOIN dimLocation
		on dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPhysician
		on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	Where 
		AdjustmentReason = 'Credentialing' 
		and LocationName = 'Angelstone Community Hospital'
	Order by ProviderNpi desc
	
	/*
	Hard: Question 11
	What is the average patientage by gender for patients
	seen at Big Heart Community Hospital with a Diagnosis
	that included Type 2 diabetes? And how many Patients
	are included in that average?
	*/

Select 
	PatientGender
	,AVG(PatientAge) as AVGPatientAge
	,Count(Distinct PatientNumber) as CountOfPatients
From(
	Select Distinct
		FactTable.PatientNumber
		,PatientGender
		,PatientAge
	From FactTable
	INNER JOIN dimPatient
		on dimPatient.dimPatientPK = FactTable.dimPatientPK
	INNER JOIN dimDiagnosisCode
		on dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
	INNER JOIN dimLocation
		on dimLocation.dimLocationPK = FactTable.dimLocationPK
	Where LocationName = 'Big Heart Community Hospital'
		and DiagnosisCodeDescription = 'Type 2 Diabetes Mellitus') a
Group by PatientGender

	/*
	Intermediate: Question 12
	There are a two visit types that you have been asked
	to compare (use CptDesc).
		- Office/outpatient visit est
		- Office/outpatient visit new
	Show each CptCode, CptDesc and the assocaited CptUnits.
	What is the Charge per CptUnit? (Reduce to two decimals)
	What does this mean? 
	*/

	select 
		CptCode
		,CptDesc
		,Sum(CPTUnits) as 'CPTUnits'
		,Format(Sum(GrossCharge) / Sum(CptUnits), '$#') as 'ChargePerUnit'
	From FactTable
	INNER JOIN dimCptCode
		on dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
	where CptDesc = 'Office/outpatient visit est'
		or CptDesc = 'Office/outpatient visit new'
	group by 
		CptCode
		,CptDesc
	order by CptCode asc

	-- what does this mean >> video on 06.17

	select distinct CptDesc
	From dimCptCode
	
	/*
	Hard: Question 13
	Similar to Question 12, you've been asked to analysis
	the PaymentperUnit (NOT ChargeperUnit). You've been 
	tasked with finding the PaymentperUnit by PayerName. 
	Do this analysis on the following visit type (CptDesc)
		- Initial hospital care
	Show each CptCode, CptDesc and associated CptUnits.
	**Note you will encounter a zero value error. If you
	can't remember what to do find the ifnull lecture in 
	Section 8. 
	What does this mean?
	*/

	select 
		CptCode
		,CptDesc
		,PayerName
		,Sum(CPTUnits) as CPTUnits
		,Format(-Sum(Payment) / Nullif(Sum(CPTUnits),0),'$#') as 'PaymentPerUnit'
	From FactTable
	INNER JOIN dimCptCode
		on dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
	INNER JOIN dimPayer
		on dimPayer.dimPayerPK = FactTable.dimPayerPK
	Where CptDesc = 'Initial hospital care'
	Group by
		CptCode
		,CptDesc
		,PayerName



	/*
	Hard: Question 14
	Within the FactTable we are able to see GrossCharges. 
	You've been asked to find the NetCharge, which means
	Contractual adjustments need to be subtracted from the
	GrossCharge (GrossCharges - Contractual Adjustments).
	After you've found the NetCharge then calculate the 
	Net Collection Rate (Payments/NetCharge) for each 
	physician specialty. Which physician specialty has the 
	worst Net Collection Rate with a NetCharge greater than 
	$25,000? What is happening here? Where are the other 
	dollars and why aren't they being collected?
	What does this mean?
	*/

--Select
--	ProviderSpecialty
--	,Sum(GrossCharge) as 'GrossCharges'
--	,Sum(Case when AdjustmentReason = 'Contractual' 
--		then Adjustment
--		Else Null
--		End) as 'ContractualAdjustment'
--	,Sum(GrossCharge) +
--		Sum(Case when AdjustmentReason = 'Contractual' 
--		then Adjustment
--		Else Null
--		End) as 'NetCharge'
--	,-Sum(Payment) / (Sum(GrossCharge) +
--		Sum(Case when AdjustmentReason = 'Contractual' 
--		then Adjustment
--		Else Null
--		End)) as NetCollectionRate
--From FactTable
--INNER JOIN dimPhysician
--	on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
--INNER JOIN dimTransaction
--	on dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
--Group by ProviderSpecialty

Select
	ProviderSpecialty
	,GrossCharges
	,ContractualAdjustment
	,NetCharges
	,Payments
	,Adjustments
	,- Payments/NetCharges as 'NetCollectionRate'
From(
	Select
		ProviderSpecialty
		,Sum(GrossCharge) as 'GrossCharges'
		,Sum(Case when Adjustmentreason = 'Contractual'
			then Adjustment
			Else Null
			End) as 'ContractualAdjustment'
		,Sum(GrossCharge) +
			Sum(Case when Adjustmentreason = 'Contractual'
			then Adjustment
			Else Null
			End) as 'NetCharges'
		,Sum(Payment) as 'Payments'
		,Sum(Adjustment) as 'Adjustments'
		,Sum(AR) as 'AR'
	From FactTable
	INNER JOIN dimPhysician
		on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	INNER JOIN dimTransaction
		on dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
	Group by ProviderSpecialty) a
Where NetCharges > 25000
Order by NetCollectionRate desc


	/*
	Easy: Question 15
	Build a Table that includes the following elements:
		- LocationName
		- CountofPhysicians
		- CountofPatients
		- GrossCharge
		- AverageChargeperPatients 
	*/


Select
	LocationName
	,Count(distinct ProviderNpi) as CountofPhysicians
	,Count(distinct dimPatient.PatientNumber) as CountofPatients
	,Sum(GrossCharge) as GrossCharges
	,Sum(GrossCharge) / Count(distinct dimPatient.PatientNumber) as AverageChargeperPatient
From FactTable
INNER JOIN dimLocation
	on dimlocation.dimLocationPK = FactTable.dimLocationPK
INNER JOIN dimPhysician
	on dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
INNER JOIN dimPatient
	on dimPatient.dimPatientPK = FactTable.dimPatientPK
Group by LocationName