#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""演示数据 SQL 自检：语法结构 + 唯一键冲突 + 外键引用完整性。"""

import re
import collections
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def split_top(s):
    parts, depth, buf, instr, i = [], 0, [], None, 0
    while i < len(s):
        c = s[i]
        if instr:
            if c == "\\":
                buf.append(c)
                buf.append(s[i + 1])
                i += 2
                continue
            if c == instr:
                instr = None
        elif c in "'\"":
            instr = c
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        if c == ";" and depth == 0 and not instr:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    return parts


def split_commas(s):
    parts, depth, buf, instr, i = [], 0, [], None, 0
    while i < len(s):
        c = s[i]
        if instr:
            if c == "\\":
                buf.append(c)
                buf.append(s[i + 1])
                i += 2
                continue
            if c == instr:
                instr = None
        elif c in "'\"":
            instr = c
        if not instr:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif c == "," and depth == 0:
                parts.append("".join(buf))
                buf = []
                i += 1
                continue
        buf.append(c)
        i += 1
    parts.append("".join(buf))
    return [p.strip() for p in parts]


def load_rows(path, table):
    """解析某张表的所有 INSERT 行，返回 {col: value} 列表。"""
    src = open(path, encoding="utf-8").read()
    rows = []
    pattern = r"INSERT INTO `%s` \(([^)]*)\) VALUES\n(.*?);\n" % table
    for m in re.finditer(pattern, src, re.S):
        cols = [c.strip("` ") for c in m.group(1).split(",")]
        for r in split_commas(m.group(2)):
            r = r.strip()
            if not (r.startswith("(") and r.endswith(")")):
                raise ValueError("行格式异常 %s: %s" % (table, r[:60]))
            vals = split_commas(r[1:-1])
            if len(vals) != len(cols):
                raise ValueError("%s 列数 %d != 值数 %d" % (table, len(cols), len(vals)))
            rows.append(dict(zip(cols, vals)))
    return rows


def main():
    schema = os.path.join(ROOT, "sql", "01_schema.sql")
    demo = os.path.join(ROOT, "sql", "02_demo_data.sql")
    ok = True

    # 1) 语法结构
    for path in (schema, demo):
        src = open(path, encoding="utf-8").read()
        stmts = [s.strip() for s in split_top(src)
                 if s.strip() and not s.lstrip().startswith("--")]
        n_ins = sum(1 for s in stmts if s.upper().startswith("INSERT"))
        print("%-30s 语句 %3d  INSERT %3d" % (os.path.basename(path), len(stmts), n_ins))

    # 2) 唯一键
    uniques = {
        "sys_user": ["username"],
        "teacher": ["teacher_no", "user_id"],
        "student": ["student_no", "user_id"],
        "thesis": ["student_id"],
        "selection": ["topic_id", "student_id"],
        "review": ["thesis_id", "reviewer_id"],
        "defense_group_member": ["group_id", "teacher_id"],
        "defense_record": ["thesis_id"],
        "thesis_score": ["thesis_id"],
        "sys_config": ["config_key"],
    }
    print("\n唯一键检查：")
    for table, key_sets in uniques.items():
        rows = load_rows(demo, table)
        for ks in ([key_sets] if isinstance(key_sets[0], str) else key_sets):
            seen = collections.Counter(tuple(r[k] for k in ks) for r in rows)
            dup = [k for k, c in seen.items() if c > 1]
            flag = "OK " if not dup else "FAIL"
            if dup:
                ok = False
            print("  [%s] %-24s %s  行数 %d" % (flag, table, "+".join(ks), len(rows)))

    # 3) 引用完整性
    print("\n引用完整性检查：")
    refs = [
        ("teacher", "user_id", "sys_user", "id"),
        ("student", "user_id", "sys_user", "id"),
        ("student", "advisor_id", "teacher", "id"),
        ("topic", "teacher_id", "teacher", "id"),
        ("selection", "topic_id", "topic", "id"),
        ("selection", "student_id", "student", "id"),
        ("selection", "handler_id", "teacher", "id"),
        ("thesis", "student_id", "student", "id"),
        ("thesis", "topic_id", "topic", "id"),
        ("thesis", "advisor_id", "teacher", "id"),
        ("proposal", "thesis_id", "thesis", "id"),
        ("proposal", "reviewer_id", "teacher", "id"),
        ("midterm_report", "thesis_id", "thesis", "id"),
        ("midterm_report", "reviewer_id", "teacher", "id"),
        ("final_submission", "thesis_id", "thesis", "id"),
        ("review", "thesis_id", "thesis", "id"),
        ("review", "reviewer_id", "teacher", "id"),
        ("defense_group", "secretary_id", "teacher", "id"),
        ("defense_group_member", "group_id", "defense_group", "id"),
        ("defense_group_member", "teacher_id", "teacher", "id"),
        ("defense_record", "thesis_id", "thesis", "id"),
        ("defense_record", "group_id", "defense_group", "id"),
        ("thesis_score", "thesis_id", "thesis", "id"),
        ("notification", "user_id", "sys_user", "id"),
        ("audit_log", "actor_id", "sys_user", "id"),
    ]
    cache = {}
    for child, ckey, parent, pkey in refs:
        if parent not in cache:
            cache[parent] = {r[pkey] for r in load_rows(demo, parent)}
        bad = []
        for r in load_rows(demo, child):
            v = r[ckey]
            if v == "NULL":
                continue
            if v not in cache[parent]:
                bad.append(v)
        if bad:
            ok = False
            print("  [FAIL] %-22s.%s -> %s.%s  悬空 %d 个: %s"
                  % (child, ckey, parent, pkey, len(bad), bad[:5]))
        else:
            print("  [OK  ] %-22s.%s -> %s.%s" % (child, ckey, parent, pkey))

    # 4) 状态分布
    print("\n论文状态分布：")
    cnt = collections.Counter(r["status"] for r in load_rows(demo, "thesis"))
    for k, v in sorted(cnt.items(), key=lambda x: -x[1]):
        print("  %-20s %d" % (k, v))

    print("\n结论：%s" % ("全部通过" if ok else "存在问题，请修复"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
