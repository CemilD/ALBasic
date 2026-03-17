/// <summary>
/// Extensible enum that maps JSON import type identifiers to their
/// concrete IPLIPriceListImporter implementations.
///
/// To register a new import type from a dependent app:
///   enumextension XXXXX "My Importer Ext" extends "PLI Importer Type"
///   { value(1; Purchase) { Implementation = "IPLIPriceListImporter" = "My Purchase PL Importer"; } }
/// </summary>
enum 70102 "PLI Importer Type" implements "IPLIPriceListImporter"
{
    Extensible = true;

    value(0; Sales)
    {
        Caption = 'Sales Price List';
        Implementation = "IPLIPriceListImporter" = "PLI Sales PL Importer";
    }
}
