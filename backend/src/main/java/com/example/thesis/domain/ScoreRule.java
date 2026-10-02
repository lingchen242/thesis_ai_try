package com.example.thesis.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * 成绩计算规则。
 * <p>总评 = 已完成评分环节的加权平均（缺失环节不计入，也不会把未评的环节按 0 分拉低总分）。
 * 权重默认 开题 20 / 中期 20 / 评阅 30 / 答辩 30，存于 sys_config，可在线调整。
 */
public final class ScoreRule {

    private ScoreRule() {
    }

    public static final BigDecimal DEFAULT_PROPOSAL_WEIGHT = new BigDecimal("20");
    public static final BigDecimal DEFAULT_MIDTERM_WEIGHT = new BigDecimal("20");
    public static final BigDecimal DEFAULT_REVIEW_WEIGHT = new BigDecimal("30");
    public static final BigDecimal DEFAULT_DEFENSE_WEIGHT = new BigDecimal("30");

    /**
     * 计算加权总评。
     *
     * @return 总评，若所有环节均无成绩返回 null
     */
    public static BigDecimal total(BigDecimal proposal, BigDecimal midterm, BigDecimal review, BigDecimal defense,
                                   BigDecimal wProposal, BigDecimal wMidterm, BigDecimal wReview, BigDecimal wDefense) {
        BigDecimal weightedSum = BigDecimal.ZERO;
        BigDecimal weightSum = BigDecimal.ZERO;

        List<BigDecimal[]> pairs = new ArrayList<>();
        pairs.add(new BigDecimal[]{proposal, wProposal});
        pairs.add(new BigDecimal[]{midterm, wMidterm});
        pairs.add(new BigDecimal[]{review, wReview});
        pairs.add(new BigDecimal[]{defense, wDefense});

        for (BigDecimal[] pair : pairs) {
            BigDecimal score = pair[0];
            BigDecimal weight = pair[1] == null ? BigDecimal.ZERO : pair[1];
            if (score != null && weight.signum() > 0) {
                weightedSum = weightedSum.add(score.multiply(weight));
                weightSum = weightSum.add(weight);
            }
        }
        if (weightSum.signum() == 0) {
            return null;
        }
        return weightedSum.divide(weightSum, 1, RoundingMode.HALF_UP);
    }

    /** 五级等级 */
    public static String levelOf(BigDecimal total) {
        if (total == null) {
            return "未完成";
        }
        double v = total.doubleValue();
        if (v >= 90) {
            return "优秀";
        }
        if (v >= 80) {
            return "良好";
        }
        if (v >= 70) {
            return "中等";
        }
        if (v >= 60) {
            return "及格";
        }
        return "不及格";
    }
}
