# ✅ Git-Branch Harjoitus: ASN-suodatuksen refaktorointi

Tämä muistilista opastaa yhden Git-branchin käytön läpi, käytännön esimerkkinä ASN-nimiin perustuvan Varnish-eston poistaminen ja yhdistäminen ASN-ID-logiikkaan.

---

## 🔧 Valmistelut

1. Siirry projektihakemistoon:
   ```bash
   cd /path/to/your/varnish-repo
   ```

2. Tarkista tilanne:
   ```bash
   git status
   git pull origin main
   ```

---

## 🌿 Uuden haaran (branchin) luonti

3. Luo uusi branch:
   ```bash
   git checkout -b refactor/asn-unify
   ```

---

## ✏️ Tee muutos

4. Poista `x-asn ~ "..."` -ehdot VCL:stä

5. Siirrä tarvittavat suodatussäännöt `x-asn-id == "12345"` -muotoon

6. Testaa syntaksi:
   ```bash
   varnishd -Cf shared_wp.vcl
   ```

---

## 💾 Tallenna muutos

7. Commit:
   ```bash
   git add path/to/changed_file.vcl
   git commit -m "Refactor: remove ASN-name match and unify with ASN-ID list"
   ```

8. (Valinnainen) Puske branch GitHubiin:
   ```bash
   git push -u origin refactor/asn-unify
   ```

---

## 🔄 Merge takaisin mainiin (jos toimii)

9. Siirry takaisin:
   ```bash
   git checkout main
   git pull origin main
   ```

10. Yhdistä:
   ```bash
   git merge refactor/asn-unify
   ```

11. (Valinnainen) Tagi onnistuneelle muutokselle:
   ```bash
   git tag -a asn-unify-20250606 -m "ASN-nimet poistettu ja ID-tarkistus yhtenäistetty"
   git push origin asn-unify-20250606
   ```

---

## 🚑 Palautus epäonnistumisen yhteydessä

12. Paluu alkuun:
   ```bash
   git checkout main
   git reset --hard origin/main
   ```

Tai palautus tagin avulla:
   ```bash
   git reset --hard asn-unify-backup
   ```

---
