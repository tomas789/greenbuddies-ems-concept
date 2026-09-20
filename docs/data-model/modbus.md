# Map Modbus once

Only the adapter knows a manufacturer's register map. Never put its address or scaling formula into a page component.

## Register mapping

```json
{
  "source": "battery-modbus",
  "functionCode": 3,
  "address": 100,
  "encoding": "int32",
  "wordOrder": "highFirst",
  "byteOrder": "highFirst",
  "scale": -1000,
  "offset": 0,
  "pollMs": 1000,
  "invalidRaw": ["80000000"]
}
```

Address is the **zero-based PDU address**, not a 4xxxx display reference. Function 3 reads holding registers; 4 reads input registers; 1/2 read coils/discrete inputs. Normalize the manual's numbering explicitly. A float or 32-bit integer spans two registers; UInt64 spans four. Read all words in one completed transaction.

## Decode in this order

1. Check transaction success and complete register count.
2. Normalize bytes within each word, then the word order.
3. Reject invalid raw patterns before interpreting the value.
4. Decode signed integer / IEEE float / counter / bit / enumeration.
5. Apply `canonical = raw × scale + offset`, once.
6. Check field bounds and attach the observation's quality and time.

`invalidRaw` uses the normalized high-word-first hexadecimal bit pattern. A register boolean names its `bit` (0–15). Vendor statuses need an explicit `enumMap`; unknown codes are bad, not “running”. UInt64 counters require scale 1 and offset 0 in the reference decoder; convert other counter units with exact integer arithmetic in the adapter.

## Check known vectors

| Registers | Encoding | Result |
| --- | --- | --- |
| 0000, 04E2 | int32, scale −1000 | −1250000 W |
| 0000, 3F80 | float32, low word first | 1.0 |
| FFFF, FFFF | int32 | −1 |
| FFFF, FFFF, FFFF, FFFF | uint64 | 18446744073709551615 |

Do not stamp each PLC scan as a new sample. CODESYS can retain old values or set zero after communication errors; neither proves a successful read. Use the actual channel/request completion and error indications.

[Modbus protocol](https://www.modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf) · [CODESYS channel behavior](https://content.helpme-codesys.com/en/CODESYS%20Modbus/_mod_edt_slave_com_channel.html) · [CODESYS request block](https://content.helpme-codesys.com/en/CODESYS%20Modbus/_mod_lib_modbusrequest.html)
