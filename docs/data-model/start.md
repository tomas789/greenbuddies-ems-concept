# Start here

A device changes its register map. Your EMS does not change. Normalize its readings into this contract in CODESYS, then publish the same points to the UI, historian and exports.

## The path

**Modbus → device adapter → canonical points → OPC UA → exporter → EMS**

1. Register the installation and equipment once in the model JSON.
2. Pick fields from the catalog. A point links one asset to one field.
3. Fill a mapping with the manufacturer's register address, encoding, order and scale.
4. Decode only completed transactions. Carry quality and the observation time with every value.
5. Publish the CODESYS structures and export complete snapshots or deltas.

## Start with the battery example

The example receives +1250 kW in a vendor's charging convention. It publishes **−1,250,000 W**: canonical power is positive discharge. SoC 674 becomes **67.4%**. Exported energy remains an exact 64-bit decimal string.

[Download the model](asset:example.model.json) · [Download a snapshot](asset:example.frame.json) · [Download CODESYS source](asset:codesys/EmsReference.st)

## Read in this order

[Model](#docs/model) defines the rules. [Modbus](#docs/modbus) shows mapping. [CODESYS](#docs/codesys) contains the code. [Export](#docs/export) connects the UI. Use the [field reference](#docs/fields) when adding equipment.

Version **1.0** is a vendor-neutral application contract. The supplied CODESYS source is a reference implementation; compile and commission it on your selected runtime. The current EMS gateway remains read-only.
