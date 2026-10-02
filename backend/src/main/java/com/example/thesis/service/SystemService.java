package com.example.thesis.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.thesis.common.BizException;
import com.example.thesis.entity.SysConfig;
import com.example.thesis.entity.SysDictItem;
import com.example.thesis.entity.SysDictType;
import com.example.thesis.mapper.SysConfigMapper;
import com.example.thesis.mapper.SysDictItemMapper;
import com.example.thesis.mapper.SysDictTypeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 系统管理：统一字典 + 系统配置。
 * <p>字典支持树形（学院 → 专业 → 班级），通过 item.parentId 关联。
 */
@Service
@RequiredArgsConstructor
public class SystemService {

    private final SysDictTypeMapper dictTypeMapper;
    private final SysDictItemMapper dictItemMapper;
    private final SysConfigMapper sysConfigMapper;

    // ======================================================= 字典类型
    public List<SysDictType> listTypes() {
        List<SysDictType> types = dictTypeMapper.selectList(new LambdaQueryWrapper<SysDictType>()
                .orderByAsc(SysDictType::getId));
        Map<String, Long> counts = dictItemMapper.countByType().stream()
                .collect(Collectors.toMap(m -> String.valueOf(m.get("typeCode")),
                        m -> Long.parseLong(String.valueOf(m.get("cnt"))), (a, b) -> a));
        types.forEach(t -> t.setItemCount(counts.getOrDefault(t.getTypeCode(), 0L).intValue()));
        return types;
    }

    public SysDictType saveType(SysDictType type) {
        if (!StringUtils.hasText(type.getTypeCode())) {
            throw BizException.param("类型编码不能为空");
        }
        type.setTypeCode(type.getTypeCode().trim().toUpperCase());
        if (type.getId() == null) {
            checkTypeCodeUnique(type.getTypeCode(), null);
            dictTypeMapper.insert(type);
        } else {
            checkTypeCodeUnique(type.getTypeCode(), type.getId());
            dictTypeMapper.updateById(type);
        }
        return type;
    }

    @Transactional
    public void deleteType(Long id) {
        SysDictType type = dictTypeMapper.selectById(id);
        if (type == null) {
            throw BizException.notFound("字典类型不存在");
        }
        Long used = dictItemMapper.selectCount(new LambdaQueryWrapper<SysDictItem>()
                .eq(SysDictItem::getTypeCode, type.getTypeCode()));
        if (used != null && used > 0) {
            throw BizException.param("该类型下还有 " + used + " 个字典项，请先删除字典项");
        }
        dictTypeMapper.deleteById(id);
    }

    private void checkTypeCodeUnique(String code, Long excludeId) {
        LambdaQueryWrapper<SysDictType> wrapper = new LambdaQueryWrapper<SysDictType>()
                .eq(SysDictType::getTypeCode, code);
        if (excludeId != null) {
            wrapper.ne(SysDictType::getId, excludeId);
        }
        if (dictTypeMapper.selectCount(wrapper) > 0) {
            throw BizException.param("类型编码已存在：" + code);
        }
    }

    // ======================================================= 字典项
    /** 平铺列表（下拉框用），可按父级过滤 */
    public List<SysDictItem> listItems(String typeCode, Long parentId, Boolean onlyEnabled) {
        LambdaQueryWrapper<SysDictItem> wrapper = new LambdaQueryWrapper<SysDictItem>()
                .eq(StringUtils.hasText(typeCode), SysDictItem::getTypeCode, typeCode)
                .eq(parentId != null, SysDictItem::getParentId, parentId)
                .orderByAsc(SysDictItem::getSortNo)
                .orderByAsc(SysDictItem::getId);
        if (Boolean.TRUE.equals(onlyEnabled)) {
            wrapper.eq(SysDictItem::getStatus, 1);
        }
        return dictItemMapper.selectList(wrapper);
    }

    /** 树形结构（字典管理页用） */
    public List<SysDictItem> tree(String typeCode) {
        List<SysDictItem> all = listItems(typeCode, null, false);
        Map<Long, SysDictItem> byId = all.stream()
                .collect(Collectors.toMap(SysDictItem::getId, Function.identity(), (a, b) -> a, LinkedHashMap::new));
        List<SysDictItem> roots = new ArrayList<>();
        for (SysDictItem item : all) {
            item.setChildren(new ArrayList<>());
            if (item.getParentId() == null) {
                roots.add(item);
            } else {
                SysDictItem parent = byId.get(item.getParentId());
                if (parent != null) {
                    item.setParentName(parent.getItemName());
                    parent.getChildren().add(item);
                } else {
                    roots.add(item);
                }
            }
        }
        return roots;
    }

    public SysDictItem saveItem(SysDictItem item) {
        if (!StringUtils.hasText(item.getTypeCode())) {
            throw BizException.param("所属字典类型不能为空");
        }
        if (!StringUtils.hasText(item.getItemName())) {
            throw BizException.param("字典项名称不能为空");
        }
        if (!StringUtils.hasText(item.getItemCode())) {
            // 未填编码时用类型 + 时间戳兜底，保证唯一键不冲突
            item.setItemCode(item.getTypeCode() + "_" + System.currentTimeMillis());
        } else {
            item.setItemCode(item.getItemCode().trim());
        }
        item.setTypeCode(item.getTypeCode().trim().toUpperCase());
        if (item.getStatus() == null) {
            item.setStatus(1);
        }
        if (item.getSortNo() == null) {
            item.setSortNo(0);
        }
        if (item.getParentId() != null) {
            SysDictItem parent = dictItemMapper.selectById(item.getParentId());
            if (parent == null) {
                throw BizException.param("上级字典项不存在");
            }
            if (item.getId() != null && item.getId().equals(item.getParentId())) {
                throw BizException.param("上级不能是自己");
            }
        }
        if (item.getId() == null) {
            checkItemCodeUnique(item.getTypeCode(), item.getItemCode(), null);
            dictItemMapper.insert(item);
        } else {
            checkItemCodeUnique(item.getTypeCode(), item.getItemCode(), item.getId());
            dictItemMapper.updateById(item);
        }
        return item;
    }

    @Transactional
    public void deleteItem(Long id) {
        SysDictItem item = dictItemMapper.selectById(id);
        if (item == null) {
            throw BizException.notFound("字典项不存在");
        }
        Long children = dictItemMapper.selectCount(new LambdaQueryWrapper<SysDictItem>()
                .eq(SysDictItem::getParentId, id));
        if (children != null && children > 0) {
            throw BizException.param("该项下还有 " + children + " 个子项，请先删除子项");
        }
        dictItemMapper.deleteById(id);
    }

    private void checkItemCodeUnique(String typeCode, String itemCode, Long excludeId) {
        LambdaQueryWrapper<SysDictItem> wrapper = new LambdaQueryWrapper<SysDictItem>()
                .eq(SysDictItem::getTypeCode, typeCode)
                .eq(SysDictItem::getItemCode, itemCode);
        if (excludeId != null) {
            wrapper.ne(SysDictItem::getId, excludeId);
        }
        if (dictItemMapper.selectCount(wrapper) > 0) {
            throw BizException.param("同一类型下编码已存在：" + itemCode);
        }
    }

    /** 校验名称是否命中某个字典类型（Excel 导入时用） */
    public boolean nameExists(String typeCode, String itemName) {
        if (!StringUtils.hasText(itemName)) {
            return false;
        }
        return dictItemMapper.selectCount(new LambdaQueryWrapper<SysDictItem>()
                .eq(SysDictItem::getTypeCode, typeCode)
                .eq(SysDictItem::getItemName, itemName.trim())) > 0;
    }

    // ======================================================= 系统配置
    public List<SysConfig> listConfigs() {
        return sysConfigMapper.selectList(new LambdaQueryWrapper<SysConfig>()
                .orderByAsc(SysConfig::getId));
    }

    /** 批量 upsert 配置 */
    @Transactional
    public void updateConfigs(List<SysConfig> configs) {
        if (configs == null) {
            return;
        }
        for (SysConfig c : configs) {
            if (!StringUtils.hasText(c.getConfigKey())) {
                continue;
            }
            SysConfig exist = sysConfigMapper.selectOne(new LambdaQueryWrapper<SysConfig>()
                    .eq(SysConfig::getConfigKey, c.getConfigKey()));
            if (exist == null) {
                sysConfigMapper.insert(c);
            } else {
                c.setId(exist.getId());
                sysConfigMapper.updateById(c);
            }
        }
    }

    /** 读取单个配置值 */
    public String getConfig(String key, String defaultValue) {
        SysConfig c = sysConfigMapper.selectOne(new LambdaQueryWrapper<SysConfig>()
                .eq(SysConfig::getConfigKey, key).last("LIMIT 1"));
        return c == null || c.getConfigValue() == null ? defaultValue : c.getConfigValue();
    }
}
