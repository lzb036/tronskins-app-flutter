[GETX] GOING TO ROUTE /wallet/locked
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ┌─ REQUEST ─────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ GET https://www.etopmarket.com/api/app/locking/fund/list?page=1&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Headers:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "content-type": "application/json",
I/flutter ( 2971): │ 💡 │     "App-Type": "app",
I/flutter ( 2971): │ 💡 │     "Platform": "android",
I/flutter ( 2971): │ 💡 │     "Accept-Language": "zh-CN",
I/flutter ( 2971): │ 💡 │     "Cookie": "locale=zh_CN;WEBID=E545576641E662A343E01C2FDE715166;JSESSIONID=E545576641E662A343E01C2FDE715166;JSESSIONI=E545576641E662A343E01C2FDE715166;",
I/flutter ( 2971): │ 💡 │     "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJodWFuZ3l1c2VuMzIxQHFxLmNvbSIsInJvbGVzIjpbXSwiaXAiOiIzNi4yNTAuMTk4LjI5IiwidHlwZSI6ImFjY2VzcyIsImp0aSI6Ijc3NmQyNTljLTdhNmMtNDRhNi1iYmM0LWEzNGU1MDY5NmEwNCIsImlhdCI6MTc3MjY3MjgxMCwiZXhwIjoxNzcyNjc0NjEwfQ.TymbCaHgLxX4y5joToDq9gRhp5Vfr-NL2AgjXfb3-Fo"
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ├─ RESPONSE ────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ 200 https://www.etopmarket.com/api/app/locking/fund/list?page=1&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Data:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "code": 0,
I/flutter ( 2971): │ 💡 │     "statusCode": 200,
I/flutter ( 2971): │ 💡 │     "datas": [
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35921",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "274423874412740608",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772602589",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35912",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "287114128789733376",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772526735",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35898",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "285974904027873280",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772248960",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.55,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35896",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "277977706501636096",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772179742",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.03,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35890",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "276999800237457408",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772095461",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35889",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "270437573422350336",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772092771",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       }
I/flutter ( 2971): │ 💡 │     ]
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 └────────────────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ┌─ REQUEST ─────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ GET https://www.etopmarket.com/api/app/locking/fund/list?page=2&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Headers:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "content-type": "application/json",
I/flutter ( 2971): │ 💡 │     "App-Type": "app",
I/flutter ( 2971): │ 💡 │     "Platform": "android",
I/flutter ( 2971): │ 💡 │     "Accept-Language": "zh-CN",
I/flutter ( 2971): │ 💡 │     "Cookie": "locale=zh_CN;WEBID=E545576641E662A343E01C2FDE715166;JSESSIONID=E545576641E662A343E01C2FDE715166;JSESSIONI=E545576641E662A343E01C2FDE715166;",
I/flutter ( 2971): │ 💡 │     "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJodWFuZ3l1c2VuMzIxQHFxLmNvbSIsInJvbGVzIjpbXSwiaXAiOiIzNi4yNTAuMTk4LjI5IiwidHlwZSI6ImFjY2VzcyIsImp0aSI6Ijc3NmQyNTljLTdhNmMtNDRhNi1iYmM0LWEzNGU1MDY5NmEwNCIsImlhdCI6MTc3MjY3MjgxMCwiZXhwIjoxNzcyNjc0NjEwfQ.TymbCaHgLxX4y5joToDq9gRhp5Vfr-NL2AgjXfb3-Fo"
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ├─ RESPONSE ────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ 200 https://www.etopmarket.com/api/app/locking/fund/list?page=2&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Data:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "code": 0,
I/flutter ( 2971): │ 💡 │     "statusCode": 200,
I/flutter ( 2971): │ 💡 │     "datas": [
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35921",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "274423874412740608",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772602589",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35912",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "287114128789733376",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772526735",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35898",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "285974904027873280",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772248960",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.55,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35896",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "277977706501636096",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772179742",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.03,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35890",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "276999800237457408",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772095461",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35889",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "270437573422350336",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772092771",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       }
I/flutter ( 2971): │ 💡 │     ]
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 └────────────────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ┌─ REQUEST ─────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ GET https://www.etopmarket.com/api/app/locking/fund/list?page=3&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Headers:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "content-type": "application/json",
I/flutter ( 2971): │ 💡 │     "App-Type": "app",
I/flutter ( 2971): │ 💡 │     "Platform": "android",
I/flutter ( 2971): │ 💡 │     "Accept-Language": "zh-CN",
I/flutter ( 2971): │ 💡 │     "Cookie": "locale=zh_CN;WEBID=E545576641E662A343E01C2FDE715166;JSESSIONID=E545576641E662A343E01C2FDE715166;JSESSIONI=E545576641E662A343E01C2FDE715166;",
I/flutter ( 2971): │ 💡 │     "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJodWFuZ3l1c2VuMzIxQHFxLmNvbSIsInJvbGVzIjpbXSwiaXAiOiIzNi4yNTAuMTk4LjI5IiwidHlwZSI6ImFjY2VzcyIsImp0aSI6Ijc3NmQyNTljLTdhNmMtNDRhNi1iYmM0LWEzNGU1MDY5NmEwNCIsImlhdCI6MTc3MjY3MjgxMCwiZXhwIjoxNzcyNjc0NjEwfQ.TymbCaHgLxX4y5joToDq9gRhp5Vfr-NL2AgjXfb3-Fo"
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ├─ RESPONSE ────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ 200 https://www.etopmarket.com/api/app/locking/fund/list?page=3&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Data:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "code": 0,
I/flutter ( 2971): │ 💡 │     "statusCode": 200,
I/flutter ( 2971): │ 💡 │     "datas": [
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35921",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "274423874412740608",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772602589",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35912",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "287114128789733376",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772526735",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35898",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "285974904027873280",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772248960",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.55,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35896",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "277977706501636096",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772179742",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.03,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35890",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "276999800237457408",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772095461",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35889",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "270437573422350336",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772092771",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       }
I/flutter ( 2971): │ 💡 │     ]
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 └────────────────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ┌─ REQUEST ─────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ GET https://www.etopmarket.com/api/app/locking/fund/list?page=4&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Headers:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "content-type": "application/json",
I/flutter ( 2971): │ 💡 │     "App-Type": "app",
I/flutter ( 2971): │ 💡 │     "Platform": "android",
I/flutter ( 2971): │ 💡 │     "Accept-Language": "zh-CN",
I/flutter ( 2971): │ 💡 │     "Cookie": "locale=zh_CN;WEBID=E545576641E662A343E01C2FDE715166;JSESSIONID=E545576641E662A343E01C2FDE715166;JSESSIONI=E545576641E662A343E01C2FDE715166;",
I/flutter ( 2971): │ 💡 │     "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJodWFuZ3l1c2VuMzIxQHFxLmNvbSIsInJvbGVzIjpbXSwiaXAiOiIzNi4yNTAuMTk4LjI5IiwidHlwZSI6ImFjY2VzcyIsImp0aSI6Ijc3NmQyNTljLTdhNmMtNDRhNi1iYmM0LWEzNGU1MDY5NmEwNCIsImlhdCI6MTc3MjY3MjgxMCwiZXhwIjoxNzcyNjc0NjEwfQ.TymbCaHgLxX4y5joToDq9gRhp5Vfr-NL2AgjXfb3-Fo"
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 ├─ RESPONSE ────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ 200 https://www.etopmarket.com/api/app/locking/fund/list?page=4&pageSize=20
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 │ Data:
I/flutter ( 2971): │ 💡 │   {
I/flutter ( 2971): │ 💡 │     "code": 0,
I/flutter ( 2971): │ 💡 │     "statusCode": 200,
I/flutter ( 2971): │ 💡 │     "datas": [
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35921",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "274423874412740608",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772602589",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35912",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "287114128789733376",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772526735",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35898",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "285974904027873280",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772248960",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.55,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35896",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "277977706501636096",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772179742",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.03,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35890",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "276999800237457408",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772095461",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 1.0,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       },
I/flutter ( 2971): │ 💡 │       {
I/flutter ( 2971): │ 💡 │         "errors": [],
I/flutter ( 2971): │ 💡 │         "id": "35889",
I/flutter ( 2971): │ 💡 │         "flag": true,
I/flutter ( 2971): │ 💡 │         "srcId": "270437573422350336",
I/flutter ( 2971): │ 💡 │         "lockTime": "1772092771",
I/flutter ( 2971): │ 💡 │         "lockType": 1,
I/flutter ( 2971): │ 💡 │         "typeName": "购买中",
I/flutter ( 2971): │ 💡 │         "amount": 0.0,
I/flutter ( 2971): │ 💡 │         "gift_amount": 0.36,
I/flutter ( 2971): │ 💡 │         "used": 0.0
I/flutter ( 2971): │ 💡 │       }
I/flutter ( 2971): │ 💡 │     ]
I/flutter ( 2971): │ 💡 │   }
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter ( 2971): │ 💡 └────────────────────────────────────────────────
I/flutter ( 2971): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
