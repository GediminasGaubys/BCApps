// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using System.TestLibraries.Utilities;

codeunit 139898 "E-Doc. Serv. Supp. Type Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    procedure SupportedTypesPageShowsAndAllowsEditingDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        SupportedTypesPage: TestPage "E-Doc Service Supported Types";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Check that the Supported Types page shows and allows editing Direction.
        // [GIVEN] An existing supported type row with Direction = Incoming
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Sales Credit Memo");

        // [WHEN] Opening page "E-Doc Service Supported Types" and changing Direction to Both
        SupportedTypesPage.OpenEdit();
        SupportedTypesPage.GoToRecord(EDocServiceSupportedType);
        Assert.AreEqual(Format(Enum::"E-Doc. Supp. Type Direction"::Incoming), SupportedTypesPage.Direction.Value(), 'Direction should show Incoming.');
        SupportedTypesPage.Direction.SetValue(Enum::"E-Doc. Supp. Type Direction"::Both);
        SupportedTypesPage.Close();

        // [THEN] The row's Direction field reflects Both after the change
        EDocServiceSupportedType.FindFirst();
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, EDocServiceSupportedType.Direction, 'Direction should be Both after edit.');
    end;

    [Test]
    procedure ExportBlockedWhenDirectionIsIncomingOnly()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Export must be blocked when a document type is configured for Incoming only.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice"), 'Export should be blocked for Incoming-only direction.');
    end;

    [Test]
    procedure ExportAllowedWhenDirectionIsOutgoingOrBoth()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Export is allowed for Outgoing and for Both.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Both);

        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice"), 'Export should be allowed for Outgoing.');
        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo"), 'Export should be allowed for Both.');
    end;

    [Test]
    procedure ImportBlockedWhenDirectionIsOutgoingOnly()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Import must be blocked when a document type is configured for Outgoing only.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Import should be blocked for Outgoing-only direction.');
    end;

    [Test]
    procedure ImportUsesFallbackPairDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] The Purchase Order/Purchase Invoice fallback pair applies Direction from whichever row matched.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsTrue(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should inherit Incoming from the Purchase Invoice fallback row.');
        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should not be supported for export via an Incoming-only fallback row.');
    end;

    [Test]
    procedure FallbackPartnerDoesNotOverrideExplicitOwnRowDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Purchase Order has its own explicit row (Outgoing only). Purchase Invoice, its fallback partner,
        // is configured Incoming. The fallback must never override an explicit row on the type actually being
        // queried: Purchase Order stays export-only, even though its partner would otherwise allow import.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order''s own Outgoing-only row must not be overridden by the Purchase Invoice fallback partner.');
        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should still be exportable via its own explicit Outgoing row.');
    end;

    [Test]
    procedure ImportAllowedWhenDocumentTypeNotConfigured()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Import was never gated by table 6122 before Direction existed, so an unconfigured type must stay permitted on upgrade.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);

        Assert.IsTrue(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Import should remain allowed when no row is configured.');
        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Export must still require an explicit row, unchanged from pre-Direction behavior.');
    end;

    [Test]
    procedure OnInsertSeedsDefaultsForServiceLeftOnDefaultFormat()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] "Document Format" defaults to enum value 0 ("Data Exchange") with no InitValue override, so a
        // service inserted through the real table (Insert(true), as a page would do) without ever touching that
        // field must still get seeded — via "E-Document Service".OnInsert self-validating the field — rather than
        // silently staying unseeded because OnValidate was never explicitly triggered by the caller.
        EDocumentService.Init();
        EDocumentService.Code := LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert(true);

        Assert.AreEqual(Enum::"E-Document Format"::"Data Exchange", EDocumentService."Document Format", 'Precondition: format must still be the untouched default.');

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 4);
        EDocServiceSupportedType.SetRange("Source Document Type", Enum::"E-Document Type"::"Sales Invoice");
        Assert.IsTrue(EDocServiceSupportedType.FindFirst(), 'Sales Invoice should be seeded by OnInsert even though Document Format was never explicitly validated.');
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
    end;

    [Test]
    procedure PEPPOLBIS30SeedingSetsOutgoingDirectionIncludingRemittanceAdvice()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] Creating a service with PEPPOL BIS 3.0 format seeds direction-aware default rows, including Remittance Advice.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();

        // [WHEN] Validating Document Format = PEPPOL BIS 3.0
        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        EDocumentService.Modify();

        // [THEN] All seeded rows, including Remittance Advice, are Outgoing
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.FindSet();
        repeat
            Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
        until EDocServiceSupportedType.Next() = 0;

        Assert.IsTrue(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), 'Remittance Advice should be seeded for PEPPOL BIS 3.0.');
    end;

    [Test]
    procedure DataExchangeSeedingSetsOutgoingDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] Creating a service with Data Exchange format seeds direction-aware default rows.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();

        // [WHEN] Validating Document Format = Data Exchange
        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"Data Exchange");
        EDocumentService.Modify();

        // [THEN] All seeded rows are Outgoing
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.FindSet();
        repeat
            Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
        until EDocServiceSupportedType.Next() = 0;
    end;

    [Test]
    procedure DataExchangeSeedingDoesNotWidenPartialConfiguration()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] Revalidating Data Exchange on a partially configured service must not add missing defaults.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"Data Exchange");
        EDocumentService.Modify();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 1);
        Assert.IsFalse(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Sales Credit Memo"), 'Sales Credit Memo should not be added to an already configured service.');
    end;

    [Test]
    procedure PEPPOLBIS30SeedingDoesNotAddRemittanceAdviceToPartialConfiguration()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] Revalidating PEPPOL BIS 3.0 on a partially configured service must not add Remittance Advice.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        EDocumentService.Modify();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 1);
        Assert.IsFalse(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), 'Remittance Advice should not be added to an already configured service.');
    end;

    [Test]
    procedure PEPPOLBIS30SeedingReplacesUntouchedDataExchangeDefaults()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [SCENARIO] Changing a newly inserted service from default Data Exchange to PEPPOL BIS 3.0 applies PEPPOL defaults.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert(true);

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 4);

        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        EDocumentService.Modify();

        EDocServiceSupportedType.SetRange("Source Document Type");
        Assert.RecordCount(EDocServiceSupportedType, 5);
        Assert.IsTrue(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), 'Remittance Advice should be added when PEPPOL replaces untouched Data Exchange defaults.');
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Remittance Advice should be seeded as Outgoing.');
    end;
}