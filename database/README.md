# database

本目录只存放数据库脚本，**由使用者本地导入**。

| 文件 | 说明 |
| --- | --- |
| `01_schema.sql` | 建表 DDL（20 张表：18 业务 + 2 字典），重复执行安全 |
| `02_demo_data.sql` | 字典基础数据 + 演示数据，可反复导入 |

## 导入

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS thesis_mgmt DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql -u root -p thesis_mgmt < database/01_schema.sql
mysql -u root -p thesis_mgmt < database/02_demo_data.sql
```

> Windows CMD 下如遇中文乱码，先执行 `chcp 65001`，或改用 Git Bash / PowerShell。

表结构、实体关系、索引设计、设计取舍、演示账号与数据重新生成方式，统一见 **[../docs/DATABASE.md](../docs/DATABASE.md)**。
