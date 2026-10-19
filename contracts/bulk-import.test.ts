import { describe, expect, it } from "vitest";
import { BULK_IMPORT_HEADERS, validateBulkImportCsv } from "./bulk-import.js";

const header = BULK_IMPORT_HEADERS.join(",");

describe("validateBulkImportCsv", () => {
  it("reports missing headers without skipping silently", () => {
    const report = validateBulkImportCsv("slug,name\nfoo,bar", {
      dryRun: true,
    });
    expect(report.invalidRows).toBeGreaterThan(0);
    expect(report.results[0]?.ok).toBe(false);
  });

  it("validates rows and flags duplicate slugs", () => {
    const csv = [
      header,
      // 13 columns: empty sku, barcode, stock_quantity then is_provisional
      "sku-a,Name A,Desc,1000,draft,unknown,wine,brand-a,Brand A,,,,true",
      "sku-a,Name B,Desc,2000,draft,unknown,wine,brand-a,Brand A,,,,false",
      "bad slug,Name C,Desc,x,draft,unknown,,,,,,,false",
    ].join("\n");

    const report = validateBulkImportCsv(csv, { dryRun: true });
    expect(report.totalRows).toBe(3);
    expect(report.duplicateSlugs).toContain("sku-a");
    expect(report.invalidRows).toBe(1);
    expect(report.validRows).toBe(2);
  });

  it("never treats dry-run as applied", () => {
    const csv = `${header}\nsku-z,Name,Desc,5000,draft,unknown,spirits,b,Brand,,,,false`;
    const report = validateBulkImportCsv(csv, { dryRun: true });
    expect(report.dryRun).toBe(true);
    expect(report.validRows).toBe(1);
  });
});
