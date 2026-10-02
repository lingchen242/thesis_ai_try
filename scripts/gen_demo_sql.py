#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
生成毕业论文管理系统演示数据 SQL。

用法：
    python scripts/gen_demo_sql.py

输出：sql/02_demo_data.sql
依赖：bcrypt（pip install bcrypt）

说明：固定随机种子，重复生成结果一致；可随时改 SOURCE 常量调整数据规模。
"""

import os
import random
import datetime

import bcrypt

SEED = 20261002
OUT_PATH = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sql", "02_demo_data.sql")
)

rnd = random.Random(SEED)

# --------------------------------------------------------------------------- #
# 规模配置
# --------------------------------------------------------------------------- #
N_ADVISOR = 18
N_REVIEWER = 6
N_STUDENT_2026 = 12          # 2026 届（流程已走完）
N_STUDENT_2027 = 43          # 2027 届（进行中）
N_OPEN_TOPIC = 10            # 未开放的课题

# 2027 届论文状态分布（有论文的 38 人）
STAGES_2027 = (
    ["DRAFT"] * 3
    + ["PROPOSAL_SUBMITTED"] * 5
    + ["PROPOSAL_APPROVED"] * 5
    + ["MIDTERM_SUBMITTED"] * 6
    + ["MIDTERM_PASSED"] * 4
    + ["FINAL_SUBMITTED"] * 5
    + ["REVIEWING"] * 5
    + ["REVIEW_PASSED"] * 3
    + ["DEFENSE_SCHEDULED"] * 2
)
# 2026 届论文状态分布（12 人）
STAGES_2026 = ["ARCHIVED"] * 6 + ["DEFENSE_DONE"] * 6

STAGE_CN = {
    "DRAFT": "待提交开题",
    "PROPOSAL_SUBMITTED": "开题待审核",
    "PROPOSAL_APPROVED": "开题已通过",
    "MIDTERM_SUBMITTED": "中期待检查",
    "MIDTERM_PASSED": "中期已通过",
    "FINAL_SUBMITTED": "定稿已提交",
    "REVIEWING": "评阅中",
    "REVIEW_PASSED": "评阅已通过",
    "DEFENSE_SCHEDULED": "待答辩",
    "DEFENSE_DONE": "答辩完成",
    "ARCHIVED": "已归档",
}

WEIGHTS = {"proposal": 0.20, "midterm": 0.20, "review": 0.30, "defense": 0.30}

COLLEGES = {
    "计算机与人工智能学院": ["计算机科学与技术", "人工智能", "数据科学与大数据技术"],
    "软件学院": ["软件工程", "网络空间安全"],
    "电子信息学院": ["电子信息工程", "通信工程"],
}
TITLES = ["教授", "副教授", "讲师", "助教"]
TOPIC_TYPES = ["理论研究", "工程设计", "软件开发", "实验研究", "调研报告"]
TOPIC_SOURCES = ["教师命题", "教师命题", "教师命题", "企业真题", "学生自拟"]

SURNAMES = list(
    "王李张刘陈杨黄赵吴周徐孙马朱胡郭何高林罗郑梁谢宋唐许韩冯邓曹彭曾肖田董袁潘"
    "于蒋蔡余杜叶程苏魏吕丁任沈姚卢姜崔钟谭陆汪范金石廖贾夏韦方白邹孟熊秦邱江尹薛段雷侯龙史陶黎贺顾毛郝龚邵万钱严戴莫孔向汤"
)
GIVEN_1 = [
    "伟", "芳", "娜", "敏", "静", "丽", "强", "磊", "洋", "艳", "勇", "军", "杰", "娟",
    "涛", "明", "超", "霞", "平", "刚", "辉", "燕", "玲", "丹", "斌", "峰", "琳", "婷",
]
GIVEN_2 = [
    "子涵", "雨欣", "浩然", "梓萱", "思远", "嘉怡", "宇航", "欣怡", "俊杰", "诗涵",
    "宇轩", "晨曦", "若曦", "天佑", "梦琪", "博文", "雅静", "一鸣", "书瑶", "锦程",
    "秀英", "秀兰", "桂英", "志强", "晓东", "雪梅", "建国", "春燕", "海燕", "文博",
]

TECH_OBJECTS = {
    "深度学习": ["医学影像分割", "工业缺陷检测", "农作物病害识别", "手写公式识别", "语音情感识别"],
    "机器学习": ["用户流失预测", "财务风险预警", "学生成绩分析", "能耗异常检测", "课程成绩预警"],
    "知识图谱": ["医疗知识图谱构建", "智能问答系统", "课程知识点推荐", "论文文献推荐"],
    "联邦学习": ["跨机构医疗数据建模", "隐私保护下的用户行为建模"],
    "边缘计算": ["视频流实时分析", "车联网消息认证", "智能家居协同控制", "无人零售结算"],
    "大语言模型": ["智能问答系统", "代码缺陷自动定位", "题库自动组卷"],
    "计算机视觉": ["人脸考勤系统", "停车位检测", "工业缺陷检测"],
    "自然语言处理": ["电商评论情感分析", "新闻文本分类", "舆情监测系统", "短视频内容审核"],
    "图神经网络": ["社交网络链路预测", "交通路网流量预测"],
    "强化学习": ["仓储机器人路径规划", "动态资源调度"],
    "多模态融合": ["短视频内容审核", "远程心电监测"],
    "迁移学习": ["小样本医学影像分类", "跨领域情感分析"],
    "时序分析": ["城市短时交通流量预测", "食堂人流预测", "供应链需求预测", "校园网流量预测"],
    "数据挖掘": ["校园一卡通消费行为分析", "图书借阅模式挖掘", "学生就业去向分析"],
    "区块链": ["电子成绩单存证", "供应链溯源系统"],
    "云原生": ["在线考试系统弹性部署", "微服务链路追踪平台"],
    "物联网": ["实验设备预约与管控", "智慧农业环境监测", "停车位检测系统"],
    "微服务架构": ["在线考试系统", "图书馆推荐系统", "校园二手交易平台", "实验设备预约系统"],
    "数字孪生": ["智能制造产线仿真", "校园能耗可视化"],
    "注意力机制": ["长文本摘要生成", "语音情感识别"],
}
ENGINEERING_TECHS = {"微服务架构", "云原生", "物联网", "区块链"}


# --------------------------------------------------------------------------- #
# 工具
# --------------------------------------------------------------------------- #
def bc(pwd: str) -> str:
    return bcrypt.hashpw(pwd.encode("utf-8"), bcrypt.gensalt(10, prefix=b"2a")).decode("utf-8")


def q(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("\\", "\\\\").replace("'", "''")
    return "'%s'" % s


def dt(d):
    return "NULL" if d is None else "'%s'" % d.strftime("%Y-%m-%d %H:%M:%S")


def rand_name():
    if rnd.random() < 0.45:
        return rnd.choice(SURNAMES) + rnd.choice(GIVEN_2)
    return rnd.choice(SURNAMES) + rnd.choice(GIVEN_1)


def rand_datetime(day, h_lo=8, h_hi=21):
    return datetime.datetime(day.year, day.month, day.day, rnd.randint(h_lo, h_hi), rnd.randint(0, 59))


def score(lo=78, hi=96):
    return round(rnd.uniform(lo, hi), 1)


D = datetime.date


# --------------------------------------------------------------------------- #
# 生成数据
# --------------------------------------------------------------------------- #
print("生成演示数据…")

users, teachers, students = [], [], []
admins = []

# ---- 管理员 -----------------------------------------------------------------
uid = 1
users.append({
    "id": uid, "username": "admin", "password": bc("admin123"), "real_name": "系统管理员",
    "role": "ADMIN", "gender": 1, "phone": "13800000000", "email": "admin@thesis.edu.cn",
    "status": 1, "last_login_time": rand_datetime(D(2026, 9, 28)),
})
admin_id = uid
uid += 1

# ---- 指导教师 ---------------------------------------------------------------
advisors = []
college_names = list(COLLEGES.keys())
for i in range(1, N_ADVISOR + 1):
    college = college_names[i % len(college_names)]
    major = rnd.choice(COLLEGES[college])
    name = rand_name()
    teacher_no = "T%04d" % (2000 + i)
    users.append({
        "id": uid, "username": "t%04d" % (2000 + i), "password": bc("123456"),
        "real_name": name, "role": "ADVISOR", "gender": rnd.choice([1, 2]),
        "phone": "138%08d" % rnd.randint(10000000, 99999999),
        "email": "t%04d@thesis.edu.cn" % (2000 + i), "status": 1,
        "last_login_time": rand_datetime(D(2026, 9, rnd.randint(20, 29))),
    })
    tid = i
    teachers.append({
        "id": tid, "user_id": uid, "teacher_no": teacher_no, "real_name": name,
        "gender": users[-1]["gender"], "title": rnd.choice(TITLES), "college": college,
        "major": major, "teacher_type": "ADVISOR", "can_review": 0,
        "max_quota": 8, "phone": users[-1]["phone"], "email": users[-1]["email"],
    })
    advisors.append({"id": tid, "user_id": uid, "name": name, "college": college, "major": major})
    uid += 1

# ---- 评阅教师 ---------------------------------------------------------------
reviewers = []
for i in range(1, N_REVIEWER + 1):
    college = college_names[(i + 1) % len(college_names)]
    major = rnd.choice(COLLEGES[college])
    name = rand_name()
    users.append({
        "id": uid, "username": "r%04d" % (3000 + i), "password": bc("123456"),
        "real_name": name, "role": "REVIEWER", "gender": rnd.choice([1, 2]),
        "phone": "139%08d" % rnd.randint(10000000, 99999999),
        "email": "r%04d@thesis.edu.cn" % (3000 + i), "status": 1,
        "last_login_time": rand_datetime(D(2026, 9, rnd.randint(20, 29))),
    })
    tid = N_ADVISOR + i
    teachers.append({
        "id": tid, "user_id": uid, "teacher_no": "T%04d" % (3000 + i), "real_name": name,
        "gender": users[-1]["gender"], "title": rnd.choice(["教授", "副教授", "副教授", "讲师"]),
        "college": college, "major": major, "teacher_type": "REVIEWER",
        "can_review": 1, "max_quota": 0, "phone": users[-1]["phone"], "email": users[-1]["email"],
    })
    reviewers.append({"id": tid, "user_id": uid, "name": name})
    uid += 1

# ---- 学生 -------------------------------------------------------------------
# 2026 届：12 人，全部有论文；2027 届：43 人，其中 38 人有论文、3 人选题待审、2 人被驳回
stage_2026 = STAGES_2026[:]
stage_2027 = STAGES_2027[:]
rnd.shuffle(stage_2026)
rnd.shuffle(stage_2027)

student_pool = []       # {sid, grade, stage(可为空), college, major, class_name, name}
sid = 1
seq = 1
for grade, n, stages in ((2026, N_STUDENT_2026, stage_2026), (2027, N_STUDENT_2027, stage_2027)):
    for i in range(n):
        college = college_names[i % len(college_names)]
        majors = COLLEGES[college]
        major = majors[i % len(majors)]
        cls = "%s%s班" % (str(grade)[2:], chr(ord("A") + (i % 3)))
        name = rand_name()
        no = "%d%04d" % (grade, seq)
        users.append({
            "id": uid, "username": "s" + no, "password": bc("123456"), "real_name": name,
            "role": "STUDENT", "gender": rnd.choice([1, 2]),
            "phone": "137%08d" % rnd.randint(10000000, 99999999),
            "email": "s%s@stu.thesis.edu.cn" % no, "status": 1,
            "last_login_time": rand_datetime(D(2026, 9, rnd.randint(15, 29))),
        })
        student_pool.append({
            "id": sid, "user_id": uid, "no": no, "name": name, "grade": str(grade),
            "college": college, "major": major, "class_name": cls,
            "stage": stages[i] if i < len(stages) else None,
            "gender": users[-1]["gender"], "phone": users[-1]["phone"], "email": users[-1]["email"],
        })
        sid += 1
        seq += 1
        uid += 1

# ---- 课题 -------------------------------------------------------------------
titles = []
for tech, objs in TECH_OBJECTS.items():
    for obj in objs:
        if tech in ENGINEERING_TECHS:
            titles.append("%s的设计与实现" % obj)
        else:
            titles.append("基于%s的%s" % (tech, obj))
rnd.shuffle(titles)
titles = titles[:60]

topics = []
with_thesis = [s for s in student_pool if s["stage"]]
topics_by_student = {}
tno = 1
for s in with_thesis:
    adv = advisors[(tno - 1) % len(advisors)]
    topics.append({
        "id": tno, "title": titles[tno - 1], "topic_type": rnd.choice(TOPIC_TYPES),
        "source": rnd.choice(TOPIC_SOURCES), "teacher_id": adv["id"],
        "grade": s["grade"], "college": adv["college"], "major": adv["major"],
        "description": "本课题围绕《%s》展开，要求学生完成需求分析、方案设计、系统实现与实验验证，"
                       "最终提交完整论文与可运行成果。" % titles[tno - 1],
        "requirement": "1. 完成不少于 8000 字的论文；2. 提交可运行的代码/原型；"
                       "3. 按时参加开题、中期与答辩各环节。",
        "capacity": 1, "selected_count": 1,
        "status": "CLOSED" if s["grade"] == "2026" else "SELECTED",
        "publish_time": rand_datetime(D(2026, 1, 6) if s["grade"] == "2026" else D(2026, 8, 28)),
        "advisor": adv,
    })
    topics_by_student[s["id"]] = tno
    tno += 1
    s["advisor"] = adv

# 10 个开放课题
open_topic_ids = []
for i in range(N_OPEN_TOPIC):
    adv = advisors[(tno - 1) % len(advisors)]
    topics.append({
        "id": tno, "title": titles[tno - 1], "topic_type": rnd.choice(TOPIC_TYPES),
        "source": rnd.choice(TOPIC_SOURCES), "teacher_id": adv["id"],
        "grade": "2027", "college": adv["college"], "major": adv["major"],
        "description": "本课题围绕《%s》展开，欢迎对该方向感兴趣的同学申报。" % titles[tno - 1],
        "requirement": "具备相关课程基础，能独立完成设计与实现。",
        "capacity": 1, "selected_count": 0, "status": "OPEN",
        "publish_time": rand_datetime(D(2026, 8, 30)),
        "advisor": adv,
    })
    open_topic_ids.append(tno)
    tno += 1

# ---- 论文与选题申请 ---------------------------------------------------------
theses, selections = [], []
selection_id = 1
for s in with_thesis:
    tid = topics_by_student[s["id"]]
    topic = next(t for t in topics if t["id"] == tid)
    adv = topic["advisor"]
    s["advisor"] = adv
    is_2026 = s["grade"] == "2026"
    start = rand_datetime(D(2026, 1, rnd.randint(8, 14)) if is_2026 else D(2026, 9, rnd.randint(1, 4)))
    theses.append({
        "id": len(theses) + 1, "student_id": s["id"], "student": s, "topic_id": tid,
        "advisor_id": adv["id"], "advisor": adv, "title": topic["title"],
        "grade": s["grade"], "college": s["college"], "major": s["major"],
        "status": s["stage"], "current_stage": STAGE_CN[s["stage"]],
        "start_time": start, "grade_is_2026": is_2026,
    })
    selections.append({
        "id": selection_id, "topic_id": tid, "student_id": s["id"], "status": "APPROVED",
        "student_remark": "对该方向有浓厚兴趣，相关课程成绩良好，希望能参与本课题。",
        "teacher_comment": "同意录取，请按时准备开题。",
        "apply_time": start, "handle_time": start + datetime.timedelta(hours=rnd.randint(2, 48)),
        "handler_id": adv["id"], "topic": topic, "student": s, "advisor": adv,
    })
    selection_id += 1

# 无论文的 5 人：3 待审 + 2 驳回
no_thesis = [s for s in student_pool if not s["stage"]]
for idx, s in enumerate(no_thesis):
    tid = open_topic_ids[idx % len(open_topic_ids)]
    topic = next(t for t in topics if t["id"] == tid)
    rejected = idx >= len(no_thesis) - 2
    selections.append({
        "id": selection_id, "topic_id": tid, "student_id": s["id"],
        "status": "REJECTED" if rejected else "PENDING",
        "student_remark": "希望申报本课题，已自学相关技术栈。",
        "teacher_comment": "名额已满，建议改选其他课题。" if rejected else None,
        "apply_time": rand_datetime(D(2026, 9, rnd.randint(24, 29))),
        "handle_time": rand_datetime(D(2026, 9, 29)) if rejected else None,
        "handler_id": topic["advisor"]["id"] if rejected else None,
        "topic": topic, "student": s, "advisor": topic["advisor"],
    })
    selection_id += 1

for s in student_pool:
    if "advisor" not in s:
        s["advisor"] = None

# ---- 各阶段材料 -------------------------------------------------------------
proposals, midterms, finals, reviews = [], [], [], []
attachments, audit_logs, notifications = [], [], []
att_id, log_id, note_id = 1, 1, 1
prop_id, mid_id, fin_id, rev_id = 1, 1, 1, 1

CLOUD = "https://cdn.workbuddy.cloud/thesis-demo"


def add_attachment(biz_type, biz_id, name, size, uploader_id, when, ext="pdf"):
    global att_id
    attachments.append({
        "id": att_id, "biz_type": biz_type, "biz_id": biz_id, "file_name": "%s.%s" % (name, ext),
        "file_url": "%s/%s/%d/%s.%s" % (CLOUD, biz_type.lower(), biz_id, name, ext),
        "file_size": size, "mime_type": "application/pdf" if ext == "pdf" else "application/zip",
        "storage_driver": "cloud", "uploader_id": uploader_id, "create_time": when,
    })
    att_id += 1
    return att_id - 1


def add_log(actor_id, actor_name, action, target_type, target_id, detail, when):
    global log_id
    audit_logs.append({
        "id": log_id, "actor_id": actor_id, "actor_name": actor_name, "action": action,
        "target_type": target_type, "target_id": target_id, "detail": detail, "create_time": when,
    })
    log_id += 1


def add_note(user_id, title, content, link, ntype, when, is_read=0):
    global note_id
    notifications.append({
        "id": note_id, "user_id": user_id, "title": title, "content": content,
        "link": link, "type": ntype, "is_read": is_read, "create_time": when,
    })
    note_id += 1


reviewer_cycle = reviewers * 4
reviewer_idx = 0

for th in theses:
    st = th["status"]
    s = th["student"]
    adv = th["advisor"]
    is26 = th["grade_is_2026"]
    base_year = 2026
    # 时间线（演示用压缩时间线，详见文件头说明）
    if is26:
        t_prop_submit = rand_datetime(D(base_year, 3, rnd.randint(2, 8)))
        t_prop_review = t_prop_submit + datetime.timedelta(days=rnd.randint(3, 7))
        t_mid_submit = rand_datetime(D(base_year, 4, rnd.randint(18, 24)))
        t_mid_review = t_mid_submit + datetime.timedelta(days=rnd.randint(2, 6))
        t_final = rand_datetime(D(base_year, 5, rnd.randint(24, 29)))
        t_review_assign = rand_datetime(D(base_year, 6, 1))
        t_review_submit = rand_datetime(D(base_year, 6, rnd.randint(3, 6)))
        t_defense = rand_datetime(D(base_year, 6, rnd.randint(10, 12)))
        t_archive = rand_datetime(D(base_year, 6, rnd.randint(20, 25)))
    else:
        t_prop_submit = rand_datetime(D(base_year, 9, rnd.randint(8, 12)))
        t_prop_review = t_prop_submit + datetime.timedelta(days=rnd.randint(1, 3))
        t_mid_submit = rand_datetime(D(base_year, 9, rnd.randint(18, 22)))
        t_mid_review = t_mid_submit + datetime.timedelta(days=rnd.randint(1, 3))
        t_final = rand_datetime(D(base_year, 9, rnd.randint(25, 28)))
        t_review_assign = rand_datetime(D(base_year, 9, 28))
        t_review_submit = rand_datetime(D(base_year, 9, rnd.randint(28, 30)))
        t_defense = datetime.datetime(base_year, 10, 15, 9, 0)
        t_archive = None

    th["t_prop_submit"] = t_prop_submit
    th["t_prop_review"] = t_prop_review
    th["t_mid_submit"] = t_mid_submit
    th["t_mid_review"] = t_mid_review
    th["t_final"] = t_final
    th["t_review_submit"] = t_review_submit
    th["t_defense"] = t_defense
    th["t_archive"] = t_archive

    add_log(adv["user_id"], adv["name"], "APPROVE_SELECTION", "SELECTION", None,
            "录取 %s 申报的课题《%s》" % (s["name"], th["title"]), th["start_time"])
    add_log(admin_id, "系统管理员", "CREATE_THESIS", "THESIS", th["id"],
            "生成论文记录，当前阶段：%s" % th["current_stage"], th["start_time"])

    # 开题报告
    if st != "DRAFT":
        pending = st == "PROPOSAL_SUBMITTED"
        att = add_attachment("PROPOSAL", prop_id, "开题报告_%s" % s["no"],
                             rnd.randint(350_000, 2_400_000), s["user_id"], t_prop_submit)
        proposals.append({
            "id": prop_id, "thesis_id": th["id"],
            "content": "## 研究背景\n\n%s\n\n## 研究内容\n\n围绕《%s》开展需求分析与方案设计。\n\n"
                       "## 技术路线\n\n采用主流技术栈完成原型实现，并通过实验验证有效性。\n\n"
                       "## 进度安排\n\n按开题、中期、定稿、答辩四阶段推进。"
                       % ("随着相关技术的快速发展，该问题具有较高的研究与应用价值。", th["title"]),
            "attachment_ids": str(att),
            "submit_time": t_prop_submit,
            "review_status": "PENDING" if pending else "APPROVED",
            "review_comment": None if pending else rnd.choice([
                "选题具有较强的实用价值，研究方案可行，同意开题。",
                "目标明确，技术路线清晰，同意开题，注意控制工作量。",
                "方案整体可行，建议补充对比实验设计，同意开题。",
                "研究内容饱满，进度安排合理，同意开题。",
            ]),
            "reviewer_id": None if pending else adv["id"],
            "review_time": None if pending else t_prop_review,
            "score": None if pending else score(80, 95),
            "thesis": th, "student": s, "advisor": adv,
        })
        th["proposal_id"] = prop_id
        th["proposal_score"] = proposals[-1]["score"]
        prop_id += 1
        add_log(s["user_id"], s["name"], "SUBMIT_PROPOSAL", "PROPOSAL", proposals[-1]["id"],
                "提交开题报告", t_prop_submit)
        if pending:
            add_note(adv["user_id"], "待审核：开题报告",
                     "%s 提交了《%s》的开题报告，请及时处理。" % (s["name"], th["title"]),
                     "/proposal/review", "FLOW", t_prop_submit)
        else:
            add_log(adv["user_id"], adv["name"], "APPROVE_PROPOSAL", "PROPOSAL",
                    proposals[-1]["id"], "开题审核通过", t_prop_review)
            add_note(s["user_id"], "开题审核结果",
                     "指导教师已通过你的开题报告。", "/thesis/mine", "FLOW", t_prop_review,
                     is_read=1)
    else:
        th["proposal_id"] = None
        th["proposal_score"] = None

    # 中期报告
    if st in ("MIDTERM_SUBMITTED", "MIDTERM_PASSED", "FINAL_SUBMITTED", "REVIEWING",
              "REVIEW_PASSED", "DEFENSE_SCHEDULED", "DEFENSE_DONE", "ARCHIVED"):
        pending = st == "MIDTERM_SUBMITTED"
        att = add_attachment("MIDTERM", mid_id, "中期报告_%s" % s["no"],
                             rnd.randint(400_000, 2_800_000), s["user_id"], t_mid_submit)
        midterms.append({
            "id": mid_id, "thesis_id": th["id"],
            "progress_percent": rnd.randint(45, 60) if pending else rnd.randint(70, 95),
            "content": "## 已完成工作\n\n完成需求分析与总体设计，核心模块已实现。\n\n"
                       "## 存在问题\n\n部分边界场景处理不够完善，实验数据尚需补充。\n\n"
                       "## 后续计划\n\n完善实验，开始论文撰写。",
            "attachment_ids": str(att),
            "submit_time": t_mid_submit,
            "review_status": "PENDING" if pending else "APPROVED",
            "review_comment": None if pending else rnd.choice([
                "进度正常，已完成核心工作，同意通过中期检查。",
                "工作量饱满，建议加快论文撰写进度。",
                "进展良好，注意补充实验对比，同意通过。",
            ]),
            "reviewer_id": None if pending else adv["id"],
            "review_time": None if pending else t_mid_review,
            "score": None if pending else score(78, 94),
            "thesis": th, "student": s, "advisor": adv,
        })
        th["midterm_score"] = midterms[-1]["score"]
        mid_id += 1
        add_log(s["user_id"], s["name"], "SUBMIT_MIDTERM", "MIDTERM", midterms[-1]["id"],
                "提交中期报告", t_mid_submit)
        if pending:
            add_note(adv["user_id"], "待检查：中期报告",
                     "%s 提交了中期报告，请检查。" % s["name"], "/midterm/review", "FLOW",
                     t_mid_submit)
        else:
            add_log(adv["user_id"], adv["name"], "APPROVE_MIDTERM", "MIDTERM",
                    midterms[-1]["id"], "中期检查通过", t_mid_review)
    else:
        th["midterm_score"] = None

    # 定稿
    if st in ("FINAL_SUBMITTED", "REVIEWING", "REVIEW_PASSED", "DEFENSE_SCHEDULED",
              "DEFENSE_DONE", "ARCHIVED"):
        att = add_attachment("FINAL", fin_id, "论文定稿_%s" % s["no"],
                             rnd.randint(1_200_000, 6_500_000), s["user_id"], t_final)
        finals.append({
            "id": fin_id, "thesis_id": th["id"],
            "file_url": "%s/final/%d/论文定稿_%s.pdf" % (CLOUD, fin_id, s["no"]),
            "file_name": "论文定稿_%s.pdf" % s["no"],
            "file_size": rnd.randint(1_200_000, 6_500_000),
            "version": 1, "note": "按导师意见修改后提交定稿。",
            "submit_time": t_final, "thesis": th,
        })
        th["submit_time"] = t_final
        fin_id += 1
        add_log(s["user_id"], s["name"], "SUBMIT_FINAL", "FINAL", finals[-1]["id"],
                "提交论文定稿", t_final)
    else:
        th.setdefault("submit_time", None)

    # 评阅
    if st in ("REVIEWING", "REVIEW_PASSED", "DEFENSE_SCHEDULED", "DEFENSE_DONE", "ARCHIVED"):
        rv = reviewer_cycle[reviewer_idx % len(reviewer_cycle)]
        reviewer_idx += 1
        pending = st == "REVIEWING"
        reviews.append({
            "id": rev_id, "thesis_id": th["id"], "reviewer_id": rv["id"],
            "assigned_by": admin_id,
            "score": None if pending else score(75, 96),
            "comment": None if pending else rnd.choice([
                "论文结构完整，工作量饱满，实验设计合理，达到本科毕业论文要求。",
                "选题有实用价值，实现较为完整，建议在讨论部分加强与已有工作的对比。",
                "论述清晰，代码与文档齐全，同意参加答辩。",
                "整体质量较好，个别图表说明需规范，同意答辩。",
            ]),
            "status": "PENDING" if pending else "SUBMITTED",
            "blind": 1 if st in ("REVIEW_PASSED", "DEFENSE_SCHEDULED", "DEFENSE_DONE", "ARCHIVED")
                     and th["id"] % 3 == 0 else 0,
            "assign_time": t_review_assign,
            "submit_time": None if pending else t_review_submit,
            "thesis": th, "reviewer": rv,
        })
        th["review_score"] = reviews[-1]["score"]
        rev_id += 1
        add_log(admin_id, "系统管理员", "ASSIGN_REVIEW", "REVIEW", reviews[-1]["id"],
                "指派 %s 评阅《%s》" % (rv["name"], th["title"]), t_review_assign)
        if pending:
            add_note(rv["user_id"], "待评阅任务",
                     "有一篇论文待你评阅：《%s》" % th["title"], "/review/mine", "FLOW",
                     t_review_assign)
        else:
            add_log(rv["user_id"], rv["name"], "SUBMIT_REVIEW", "REVIEW", reviews[-1]["id"],
                    "提交评阅意见，成绩 %s" % reviews[-1]["score"], t_review_submit)
    else:
        th["review_score"] = None

# ---- 答辩组 -----------------------------------------------------------------
groups = []
finished_theses = [t for t in theses if t["status"] in ("DEFENSE_DONE", "ARCHIVED")]
planned_theses = [t for t in theses if t["status"] == "DEFENSE_SCHEDULED"]

group_defs = [
    {"name": "2026届答辩一组", "grade": "2026", "status": "FINISHED",
     "date": datetime.datetime(2026, 6, 11, 9, 0), "members": finished_theses[:6]},
    {"name": "2026届答辩二组", "grade": "2026", "status": "FINISHED",
     "date": datetime.datetime(2026, 6, 12, 9, 0), "members": finished_theses[6:]},
    {"name": "2027届答辩一组", "grade": "2027", "status": "PLANNED",
     "date": datetime.datetime(2026, 10, 15, 9, 0), "members": planned_theses},
]

group_members, defense_records, thesis_scores = [], [], []
gid = 1
for gd in group_defs:
    chair = reviewers[(gid - 1) % len(reviewers)]
    member_pool = [a for a in advisors if a["id"] % 3 == (gid - 1) % 3][:3]
    groups.append({
        "id": gid, "name": gd["name"], "grade": gd["grade"],
        "college": "计算机与人工智能学院", "defense_date": gd["date"],
        "location": "实验楼 %d-%03d" % (gid, 201 + gid),
        "secretary_id": member_pool[0]["id"] if member_pool else chair["id"],
        "status": gd["status"], "remark": "请提前 15 分钟到场，携带论文纸质版三份。",
    })
    group_members.extend([
        {"group_id": gid, "teacher_id": chair["id"], "role": "CHAIR"},
        {"group_id": gid, "teacher_id": member_pool[0]["id"], "role": "SECRETARY"},
        {"group_id": gid, "teacher_id": member_pool[1]["id"], "role": "MEMBER"},
        {"group_id": gid, "teacher_id": member_pool[2]["id"], "role": "MEMBER"},
    ])

    if gd["status"] == "FINISHED":
        for th in gd["members"]:
            d = gd["date"] + datetime.timedelta(minutes=15 * (gd["members"].index(th) + 1))
            dscore = score(76, 95)
            defense_records.append({
                "id": len(defense_records) + 1, "thesis_id": th["id"], "group_id": gid,
                "score": dscore, "result": "PASS" if dscore >= 60 else "DEFER",
                "comment": rnd.choice([
                    "陈述清楚，回答问题准确，答辩通过。",
                    "演示完整，对关键技术理解到位，通过答辩。",
                    "整体表现良好，建议进一步完善文档，通过答辩。",
                ]),
                "recorded_by": admin_id, "recorded_time": d,
            })
            th["defense_score"] = dscore
            p = th.get("proposal_score") or 0
            m = th.get("midterm_score") or 0
            r = th.get("review_score") or 0
            total = round(p * WEIGHTS["proposal"] + m * WEIGHTS["midterm"]
                          + r * WEIGHTS["review"] + dscore * WEIGHTS["defense"], 1)
            thesis_scores.append({
                "id": len(thesis_scores) + 1, "thesis_id": th["id"],
                "proposal_score": p, "midterm_score": m, "review_score": r,
                "defense_score": dscore, "total_score": total,
                "computed_time": d + datetime.timedelta(days=1),
            })
            add_log(admin_id, "系统管理员", "RECORD_DEFENSE", "DEFENSE",
                    defense_records[-1]["id"], "录入答辩成绩 %s" % dscore, d)
            add_note(th["student"]["user_id"], "答辩成绩已发布",
                     "你的答辩成绩为 %s，总评 %s。" % (dscore, total), "/thesis/mine",
                     "SCORE", d + datetime.timedelta(days=1), is_read=1)
    gid += 1

# 归档留痕
for th in theses:
    if th["status"] == "ARCHIVED":
        th["archive_time"] = th["t_archive"]
        add_log(admin_id, "系统管理员", "ARCHIVE_THESIS", "THESIS", th["id"],
                "论文材料归档完成", th["t_archive"])
    else:
        th["archive_time"] = None

# ---- 系统配置 ---------------------------------------------------------------
configs = [
    ("score.weight.proposal", "20", "开题成绩权重（%）"),
    ("score.weight.midterm", "20", "中期成绩权重（%）"),
    ("score.weight.review", "30", "评阅成绩权重（%）"),
    ("score.weight.defense", "30", "答辩成绩权重（%）"),
    ("deadline.proposal", "2026-10-15", "开题报告提交截止日期"),
    ("deadline.midterm", "2026-11-30", "中期报告提交截止日期"),
    ("deadline.final", "2026-12-31", "论文定稿提交截止日期"),
    ("review.blind.enabled", "false", "是否默认启用盲审"),
    ("topic.max.per.teacher", "8", "每位指导教师最大在指导学生数"),
    ("current.grade", "2027", "当前默认届别"),
]

print("  用户 %d / 教师 %d / 学生 %d / 课题 %d / 论文 %d"
      % (len(users), len(teachers), len(student_pool), len(topics), len(theses)))
print("  开题 %d / 中期 %d / 定稿 %d / 评阅 %d / 答辩成绩 %d / 附件 %d / 日志 %d / 消息 %d"
      % (len(proposals), len(midterms), len(finals), len(reviews), len(defense_records),
         len(attachments), len(audit_logs), len(notifications)))


# --------------------------------------------------------------------------- #
# 输出 SQL
# --------------------------------------------------------------------------- #
def emit_insert(f, table, cols, rows, chunk=20):
    if not rows:
        return
    for i in range(0, len(rows), chunk):
        part = rows[i:i + chunk]
        f.write("INSERT INTO `%s` (%s) VALUES\n" % (table, ", ".join("`%s`" % c for c in cols)))
        f.write(",\n".join("  (%s)" % ", ".join(part[r][c] for c in cols) for r in range(len(part))))
        f.write(";\n\n")


os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write("""-- =============================================================================
-- 毕业论文管理系统 · 演示数据
-- 生成脚本：scripts/gen_demo_sql.py（固定随机种子，可重复生成）
-- 导入：mysql -u root -p thesis_mgmt < sql/02_demo_data.sql
--
-- 账号与密码（BCrypt 加密，cost=10）：
--   管理员      admin          / admin123
--   指导教师    t2001~t2018    / 123456
--   评阅教师    r3001~r3006    / 123456
--   学生        s20260001...   / 123456
--
-- 数据规模：
--   管理员 1 / 指导教师 %d / 评阅教师 %d / 学生 %d（2026届 %d，2027届 %d）
--   课题 %d（已选 %d，开放 %d） / 选题申请 %d / 论文 %d（覆盖 11 种状态）
--   开题 %d / 中期 %d / 定稿 %d / 评阅 %d / 答辩组 %d / 答辩成绩 %d
--   附件 %d / 操作日志 %d / 站内消息 %d
--
-- 时间线说明：为便于一次性演示全部状态，2026 届按 2026-01~06 的真实节奏排布，
-- 2027 届各环节集中在 2026-08~09（压缩时间线），答辩计划于 2026-10-15 进行。
-- =============================================================================

SET NAMES utf8mb4;

TRUNCATE TABLE `audit_log`;
TRUNCATE TABLE `notification`;
TRUNCATE TABLE `attachment`;
TRUNCATE TABLE `thesis_score`;
TRUNCATE TABLE `defense_record`;
TRUNCATE TABLE `defense_group_member`;
TRUNCATE TABLE `defense_group`;
TRUNCATE TABLE `review`;
TRUNCATE TABLE `final_submission`;
TRUNCATE TABLE `midterm_report`;
TRUNCATE TABLE `proposal`;
TRUNCATE TABLE `thesis`;
TRUNCATE TABLE `selection`;
TRUNCATE TABLE `topic`;
TRUNCATE TABLE `student`;
TRUNCATE TABLE `teacher`;
TRUNCATE TABLE `sys_user`;
TRUNCATE TABLE `sys_config`;

""" % (N_ADVISOR, N_REVIEWER, len(student_pool), N_STUDENT_2026, N_STUDENT_2027,
        len(topics), len(with_thesis), N_OPEN_TOPIC, len(selections), len(theses),
        len(proposals), len(midterms), len(finals), len(reviews), len(groups),
        len(defense_records), len(attachments), len(audit_logs), len(notifications)))

    # sys_user
    rows = [{
        "id": q(u["id"]), "username": q(u["username"]), "password": q(u["password"]),
        "real_name": q(u["real_name"]), "role": q(u["role"]), "gender": q(u["gender"]),
        "avatar": "NULL", "phone": q(u.get("phone")), "email": q(u.get("email")),
        "status": q(u["status"]), "last_login_time": dt(u["last_login_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for u in users]
    f.write("-- 1. 账号（sys_user）\n")
    emit_insert(f, "sys_user", ["id", "username", "password", "real_name", "role", "gender",
                                "avatar", "phone", "email", "status", "last_login_time",
                                "create_time", "update_time", "deleted"], rows, chunk=5)

    # teacher
    rows = [{
        "id": q(t["id"]), "user_id": q(t["user_id"]), "teacher_no": q(t["teacher_no"]),
        "real_name": q(t["real_name"]), "gender": q(t["gender"]), "title": q(t["title"]),
        "college": q(t["college"]), "major": q(t["major"]),
        "teacher_type": q(t["teacher_type"]), "can_review": q(t["can_review"]),
        "max_quota": q(t["max_quota"]), "phone": q(t["phone"]), "email": q(t["email"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for t in teachers]
    f.write("-- 2. 教师档案（teacher）\n")
    emit_insert(f, "teacher", ["id", "user_id", "teacher_no", "real_name", "gender", "title",
                               "college", "major", "teacher_type", "can_review", "max_quota",
                               "phone", "email", "create_time", "update_time", "deleted"], rows)

    # student
    rows = [{
        "id": q(s["id"]), "user_id": q(s["user_id"]), "student_no": q(s["no"]),
        "real_name": q(s["name"]), "gender": q(s["gender"]), "grade": q(s["grade"]),
        "college": q(s["college"]), "major": q(s["major"]), "class_name": q(s["class_name"]),
        "advisor_id": q(s["advisor"]["id"] if s.get("advisor") else None),
        "phone": q(s["phone"]), "email": q(s["email"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for s in student_pool]
    f.write("-- 3. 学生档案（student）\n")
    emit_insert(f, "student", ["id", "user_id", "student_no", "real_name", "gender", "grade",
                               "college", "major", "class_name", "advisor_id", "phone", "email",
                               "create_time", "update_time", "deleted"], rows)

    # topic
    rows = [{
        "id": q(t["id"]), "title": q(t["title"]), "topic_type": q(t["topic_type"]),
        "source": q(t["source"]), "teacher_id": q(t["teacher_id"]), "grade": q(t["grade"]),
        "college": q(t["college"]), "major": q(t["major"]),
        "description": q(t["description"]), "requirement": q(t["requirement"]),
        "capacity": q(t["capacity"]), "selected_count": q(t["selected_count"]),
        "status": q(t["status"]), "publish_time": dt(t["publish_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for t in topics]
    f.write("-- 4. 课题（topic）\n")
    emit_insert(f, "topic", ["id", "title", "topic_type", "source", "teacher_id", "grade",
                             "college", "major", "description", "requirement", "capacity",
                             "selected_count", "status", "publish_time", "create_time",
                             "update_time", "deleted"], rows)

    # selection
    rows = [{
        "id": q(s["id"]), "topic_id": q(s["topic_id"]), "student_id": q(s["student_id"]),
        "status": q(s["status"]), "student_remark": q(s["student_remark"]),
        "teacher_comment": q(s["teacher_comment"]), "apply_time": dt(s["apply_time"]),
        "handle_time": dt(s["handle_time"]), "handler_id": q(s["handler_id"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for s in selections]
    f.write("-- 5. 选题申请（selection）\n")
    emit_insert(f, "selection", ["id", "topic_id", "student_id", "status", "student_remark",
                                 "teacher_comment", "apply_time", "handle_time", "handler_id",
                                 "create_time", "update_time", "deleted"], rows)

    # thesis
    rows = [{
        "id": q(t["id"]), "student_id": q(t["student_id"]), "topic_id": q(t["topic_id"]),
        "advisor_id": q(t["advisor_id"]), "title": q(t["title"]), "grade": q(t["grade"]),
        "college": q(t["college"]), "major": q(t["major"]), "status": q(t["status"]),
        "current_stage": q(t["current_stage"]), "start_time": dt(t["start_time"]),
        "submit_time": dt(t.get("submit_time")), "archive_time": dt(t.get("archive_time")),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for t in theses]
    f.write("-- 6. 论文主表（thesis）\n")
    emit_insert(f, "thesis", ["id", "student_id", "topic_id", "advisor_id", "title", "grade",
                              "college", "major", "status", "current_stage", "start_time",
                              "submit_time", "archive_time", "create_time", "update_time",
                              "deleted"], rows)

    # proposal
    rows = [{
        "id": q(p["id"]), "thesis_id": q(p["thesis_id"]), "content": q(p["content"]),
        "attachment_ids": q(p["attachment_ids"]), "submit_time": dt(p["submit_time"]),
        "review_status": q(p["review_status"]), "review_comment": q(p["review_comment"]),
        "reviewer_id": q(p["reviewer_id"]), "review_time": dt(p["review_time"]),
        "score": q(p["score"]), "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for p in proposals]
    f.write("-- 7. 开题报告（proposal）\n")
    emit_insert(f, "proposal", ["id", "thesis_id", "content", "attachment_ids", "submit_time",
                                "review_status", "review_comment", "reviewer_id", "review_time",
                                "score", "create_time", "update_time", "deleted"], rows)

    # midterm_report
    rows = [{
        "id": q(m["id"]), "thesis_id": q(m["thesis_id"]),
        "progress_percent": q(m["progress_percent"]), "content": q(m["content"]),
        "attachment_ids": q(m["attachment_ids"]), "submit_time": dt(m["submit_time"]),
        "review_status": q(m["review_status"]), "review_comment": q(m["review_comment"]),
        "reviewer_id": q(m["reviewer_id"]), "review_time": dt(m["review_time"]),
        "score": q(m["score"]), "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for m in midterms]
    f.write("-- 8. 中期报告（midterm_report）\n")
    emit_insert(f, "midterm_report", ["id", "thesis_id", "progress_percent", "content",
                                      "attachment_ids", "submit_time", "review_status",
                                      "review_comment", "reviewer_id", "review_time", "score",
                                      "create_time", "update_time", "deleted"], rows)

    # final_submission
    rows = [{
        "id": q(x["id"]), "thesis_id": q(x["thesis_id"]), "file_url": q(x["file_url"]),
        "file_name": q(x["file_name"]), "file_size": q(x["file_size"]),
        "version": q(x["version"]), "note": q(x["note"]), "submit_time": dt(x["submit_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for x in finals]
    f.write("-- 9. 论文定稿（final_submission）\n")
    emit_insert(f, "final_submission", ["id", "thesis_id", "file_url", "file_name", "file_size",
                                        "version", "note", "submit_time", "create_time",
                                        "update_time", "deleted"], rows)

    # review
    rows = [{
        "id": q(r["id"]), "thesis_id": q(r["thesis_id"]), "reviewer_id": q(r["reviewer_id"]),
        "assigned_by": q(r["assigned_by"]), "score": q(r["score"]), "comment": q(r["comment"]),
        "status": q(r["status"]), "blind": q(r["blind"]),
        "assign_time": dt(r["assign_time"]), "submit_time": dt(r["submit_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for r in reviews]
    f.write("-- 10. 评阅（review）\n")
    emit_insert(f, "review", ["id", "thesis_id", "reviewer_id", "assigned_by", "score",
                              "comment", "status", "blind", "assign_time", "submit_time",
                              "create_time", "update_time", "deleted"], rows)

    # defense_group
    rows = [{
        "id": q(g["id"]), "name": q(g["name"]), "grade": q(g["grade"]),
        "college": q(g["college"]), "defense_date": dt(g["defense_date"]),
        "location": q(g["location"]), "secretary_id": q(g["secretary_id"]),
        "status": q(g["status"]), "remark": q(g["remark"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for g in groups]
    f.write("-- 11. 答辩组（defense_group）\n")
    emit_insert(f, "defense_group", ["id", "name", "grade", "college", "defense_date",
                                     "location", "secretary_id", "status", "remark",
                                     "create_time", "update_time", "deleted"], rows)

    # defense_group_member
    rows = [{"id": q(i + 1), "group_id": q(m["group_id"]), "teacher_id": q(m["teacher_id"]),
             "role_in_group": q(m["role"]), "create_time": "NOW()"}
            for i, m in enumerate(group_members)]
    f.write("-- 12. 答辩组成员（defense_group_member）\n")
    emit_insert(f, "defense_group_member", ["id", "group_id", "teacher_id", "role_in_group",
                                            "create_time"], rows)

    # defense_record
    rows = [{
        "id": q(r["id"]), "thesis_id": q(r["thesis_id"]), "group_id": q(r["group_id"]),
        "score": q(r["score"]), "result": q(r["result"]), "comment": q(r["comment"]),
        "recorded_by": q(r["recorded_by"]), "recorded_time": dt(r["recorded_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for r in defense_records]
    f.write("-- 13. 答辩成绩（defense_record）\n")
    emit_insert(f, "defense_record", ["id", "thesis_id", "group_id", "score", "result",
                                      "comment", "recorded_by", "recorded_time", "create_time",
                                      "update_time", "deleted"], rows)

    # thesis_score
    rows = [{
        "id": q(s["id"]), "thesis_id": q(s["thesis_id"]),
        "proposal_score": q(s["proposal_score"]), "midterm_score": q(s["midterm_score"]),
        "review_score": q(s["review_score"]), "defense_score": q(s["defense_score"]),
        "total_score": q(s["total_score"]), "computed_time": dt(s["computed_time"]),
        "create_time": "NOW()", "update_time": "NOW()", "deleted": "0",
    } for s in thesis_scores]
    f.write("-- 14. 成绩汇总（thesis_score）\n")
    emit_insert(f, "thesis_score", ["id", "thesis_id", "proposal_score", "midterm_score",
                                    "review_score", "defense_score", "total_score",
                                    "computed_time", "create_time", "update_time",
                                    "deleted"], rows)

    # attachment
    rows = [{
        "id": q(a["id"]), "biz_type": q(a["biz_type"]), "biz_id": q(a["biz_id"]),
        "file_name": q(a["file_name"]), "file_url": q(a["file_url"]),
        "file_size": q(a["file_size"]), "mime_type": q(a["mime_type"]),
        "storage_driver": q(a["storage_driver"]), "uploader_id": q(a["uploader_id"]),
        "create_time": dt(a["create_time"]), "update_time": "NOW()", "deleted": "0",
    } for a in attachments]
    f.write("-- 15. 附件（attachment）\n")
    emit_insert(f, "attachment", ["id", "biz_type", "biz_id", "file_name", "file_url",
                                  "file_size", "mime_type", "storage_driver", "uploader_id",
                                  "create_time", "update_time", "deleted"], rows)

    # audit_log
    rows = [{
        "id": q(l["id"]), "actor_id": q(l["actor_id"]), "actor_name": q(l["actor_name"]),
        "action": q(l["action"]), "target_type": q(l["target_type"]),
        "target_id": q(l["target_id"]), "detail": q(l["detail"]),
        "create_time": dt(l["create_time"]),
    } for l in audit_logs]
    f.write("-- 16. 操作留痕（audit_log）\n")
    emit_insert(f, "audit_log", ["id", "actor_id", "actor_name", "action", "target_type",
                                 "target_id", "detail", "create_time"], rows)

    # notification
    rows = [{
        "id": q(n["id"]), "user_id": q(n["user_id"]), "title": q(n["title"]),
        "content": q(n["content"]), "link": q(n["link"]), "type": q(n["type"]),
        "is_read": q(n["is_read"]), "create_time": dt(n["create_time"]),
    } for n in notifications]
    f.write("-- 17. 站内消息（notification）\n")
    emit_insert(f, "notification", ["id", "user_id", "title", "content", "link", "type",
                                    "is_read", "create_time"], rows)

    # sys_config
    rows = [{"id": q(i + 1), "config_key": q(k), "config_value": q(v), "remark": q(r),
             "create_time": "NOW()", "update_time": "NOW()"}
            for i, (k, v, r) in enumerate(configs)]
    f.write("-- 18. 系统配置（sys_config）\n")
    emit_insert(f, "sys_config", ["id", "config_key", "config_value", "remark", "create_time",
                                  "update_time"], rows)

    f.write("-- 演示数据生成完毕。\n")

print("已写入：%s" % OUT_PATH)
