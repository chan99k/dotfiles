# Phase 5 Area 1: Inventory Item (상품 조회 허브) - ItemResolver 적용

## Context

Phase 4에서 Item 인터페이스, NewItem, LegacyItem, ItemResolver 인프라를 구축 완료했다.
이제 **서비스 레이어에서 실제로 ItemResolver를 사용하도록 전환**하는 Phase 5의 첫 번째 영역(Area 1)을 진행한다.

CommercialItemAdapter가 유일한 GoodsRepository 직접 호출 지점이므로, 이 어댑터 레벨에서 전환하면 상위 서비스(ReadItemService 등) 변경이 최소화된다.

## Step 0: 문서 Index 생성

**목적:** 전체 진척도를 한눈에 파악하고, 새 세션 시작 시 어디서부터 읽을지 결정할 수 있는 진입점

**생성 파일:** `docs/plans/INDEX.md`

**내용:**
```markdown
# WMS-727 상품 통합 - 문서 Index

> 새 세션 시작 시 이 문서를 먼저 읽으세요.
> 마지막 업데이트: YYYY-MM-DD

## 현재 상태
- **브랜치:** feature/WMS-727
- **현재 Phase:** Phase 5 - Area 1 (상품 조회 허브 전환)
- **현재 Step:** Step 1 (Item 인터페이스 타입 개선)

## 진척도

| Phase | 상태 | 설명 |
|-------|------|------|
| Phase 1 | ✅ 완료 | 필드 분석 |
| Phase 2 | ✅ 완료 | DDL, 마이그레이션, 엔티티 |
| Phase 3 | ✅ 완료 | Item Aggregate Root |
| Phase 4 | ✅ 완료 | Item 통합 인프라 |
| Phase 5 Area 1 | 🔄 진행중 | 상품 조회 허브 (CommercialItemAdapter) |
| Phase 5 Area 2~7 | ⏳ 대기 | ItemOption, 마이그레이션, Inbound, Outbound, 재고실사, GLP |

## 문서 목록

### 진행 관리 (먼저 읽기)
| 문서 | 용도 |
|------|------|
| `docs/plans/INDEX.md` | **이 문서** - 전체 진척도, 세션 시작점 |
| `docs/wms-727-todo.md` | 전체 TODO 관리 (Phase별 체크리스트) |

### Phase별 상세 계획
| 문서 | Phase | 용도 |
|------|-------|------|
| `.claude/plans/product-field-analysis.md` | Phase 1 | Goods/ItemOption 필드 분석 결과 |
| `docs/plans/2026-02-09-product-migration-implementation.md` | Phase 2 | DDL, 마이그레이션 실행 플랜 |
| `docs/plans/2026-02-11-item-aggregate-root.md` | Phase 3 | Item Aggregate Root 구현 플랜 |
| `docs/plans/2026-02-11-item-integration-design.md` | Phase 4 | Item 통합 설계 (브레인스토밍 결과) |
| `docs/plans/2026-02-11-item-interface-infrastructure.md` | Phase 4 | Item 인프라 구현 플랜 |
| `docs/plans/2026-02-12-phase5-itemresolver-rollout.md` | Phase 5 | 7개 영역 적용 계획 (브레인스토밍 결과) |

### 참고 문서
| 문서 | 용도 |
|------|------|
| `docs/product-migration-guide.md` | 마이그레이션 가이드 |
| `docs/project-completion-summary.md` | Phase 2 완료 요약 |

## 새 세션 시작 가이드
1. 이 INDEX.md에서 "현재 상태" 확인
2. 해당 Phase의 상세 계획 문서 읽기
3. `docs/wms-727-todo.md`에서 다음 할 일 확인
4. 작업 완료 후 INDEX.md의 "현재 상태" 갱신
```

**매 Step/Area 완료 시 INDEX.md의 "현재 상태" 섹션을 갱신한다.**

---

## Step 1: Item 인터페이스 타입 개선 (String → Boolean)

**목적:** `CommercialItemDto`(Boolean)와 `Item` 인터페이스를 타입 일치시켜 매핑 단순화

**변경 내용:**

| 파일 | 변경 |
|------|------|
| `src/main/java/com/ktown4u/gms/product/domain/Item.java` | `String getGiftYn()` → `Boolean isGift()`, `String getTubeYn()` → `Boolean isTube()`, `String getDelYn()` → `Boolean isDeleted()` |
| `src/main/java/com/ktown4u/gms/product/domain/NewItem.java` | `"Y".equals(omsProduct.getGiftYn())` 등으로 변환 |
| `src/main/java/com/ktown4u/gms/product/domain/LegacyItem.java` | `goods.isGift()` 등 기존 Boolean 메서드 활용 |
| `src/test/java/com/ktown4u/gms/product/domain/NewItemTest.java` | 해당 assertion 수정 |
| `src/test/java/com/ktown4u/gms/product/domain/LegacyItemTest.java` | 해당 assertion 수정 |

**안전성:** 현재 `getGiftYn()`/`getTubeYn()`/`getDelYn()`을 호출하는 외부 비즈니스 로직 없음 (인터페이스 정의와 구현체에서만 사용). `Goods`에 이미 `isGift()`, `isTube()`, `isDeleted()` 존재.

**검증:** `./gradlew test --tests "com.ktown4u.gms.product.*"`

---

## Step 2: ItemRepository 검색 메서드 추가 (TDD)

**목적:** CommercialItemPort의 리스트 조회를 gms_oms_product에서도 수행할 수 있도록 준비

**추가 메서드 (ItemRepository 포트):**

```java
// findAllByIdAndCondition 대응
List<NewItem> findAllBy(List<Long> hmmallGoodsIds, List<String> codes, List<String> barcodes);

// listOf 대응
List<NewItem> searchBy(List<Long> hmmallGoodsIds, String code, String name, String barcode);

// listGoodsExpandedByNewItemNos 대응
List<NewItem> findAllByNewItemNos(List<Long> hmmallGoodsIds);
```

**구현 파일:**

| 파일 | 변경 |
|------|------|
| `src/main/java/com/ktown4u/gms/product/application/port/out/ItemRepository.java` | 3개 메서드 추가 |
| `src/main/java/com/ktown4u/gms/product/adapter/out/persistence/ItemPersistenceAdapter.java` | QueryDSL로 구현 |
| `src/main/java/com/ktown4u/gms/product/adapter/out/persistence/GmsOmsProductJpaRepository.java` | 필요시 커스텀 쿼리 |

**쿼리 패턴 참조 (GoodsRepository MyBatis → JPA/QueryDSL):**

- `findAllBy`: 동적 WHERE + IN 절 (ids, codes, barcodes). barcodes는 `barcode`와 `offline_barcode` 모두 검색
- `searchBy`: 동적 WHERE + 단일값/LIKE (code 정확, name LIKE, barcode 정확)
- `findAllByNewItemNos`: 입력 goodsNos → new_item_no 수집 → 같은 new_item_no를 가진 모든 상품 확장 조회 (2단계 쿼리)

**참고:** `catalog.ITEM_BARCODE` 조인은 초기에는 생략. gms_oms_product의 barcode/offline_barcode만으로 검색. 추후 필요시 추가.

**검증:** `./gradlew test --tests "com.ktown4u.gms.product.*"`

---

## Step 3: CommercialItemAdapter에 ItemResolver 분기 주입

**목적:** Feature Flag 기반으로 GoodsRepository/ItemRepository 분기

**변경 내용:**

| 파일 | 변경 |
|------|------|
| `src/main/java/com/ktown4u/gms/inventory/item/adapter/out/persistence/CommercialItemAdapter.java` | ItemRepository + FeatureFlags 의존성 추가, 각 메서드에서 분기 로직 |

**분기 로직 (각 메서드):**
```
if featureFlags.isEnabled("PRODUCT_MIGRATION"):
    ItemRepository로 조회 → NewItem → mapToItemDto(Item)
else:
    기존 GoodsRepository → Goods → mapToItemDto(Goods)  // 그대로 유지
```

**mapToItemDto(Item) 추가:**
```java
private CommercialItemDto mapToItemDto(Item item) {
    return new CommercialItemDto(
        item.getGoodsNo(),
        item.getProductName(),
        item.getCode(),
        item.getImageUrl(),
        item.getGoodsType(),
        item.isGift(),      // Step 1에서 Boolean으로 변경됨
        item.isTube(),
        item.getBarcode(),
        item.getOfflineBarcode(),
        item.getRemark(),
        item.getWeight(),
        item.getRealWeight(),
        item.getCostPrice(),
        item.getVat(),
        item.getReleaseDate(),
        item.getSupplierName(),
        item.getSupplierGoodsCode(),
        item.getNewItemNo(),
        item.isDeleted()
    );
}
```

**listMigratingGoodsBy 처리:** 마이그레이션 전용이므로 이 메서드는 GoodsRepository 경로 유지 (Area 3에서 처리)

**검증:**
- `./gradlew test --tests "com.ktown4u.gms.inventory.item.*"`
- `./gradlew test --tests "com.ktown4u.gms.product.*"`

---

## Step 4: 문서 업데이트

| 파일 | 변경 |
|------|------|
| `docs/plans/INDEX.md` | 현재 상태 갱신 (Area 1 완료, Area 2 진행중으로) |
| `docs/plans/2026-02-12-phase5-itemresolver-rollout.md` | Area 1 완료 표시 |
| `docs/wms-727-todo.md` | Area 1 체크 완료 |

---

## 전체 검증

```bash
# 1. product 도메인 테스트
./gradlew test --tests "com.ktown4u.gms.product.*"

# 2. inventory item 도메인 테스트
./gradlew test --tests "com.ktown4u.gms.inventory.item.*"

# 3. 전체 빌드
./gradlew build
```
