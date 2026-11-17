# PLAN.md - Blok Oyunu Gidişat Planı

## Hedef

480x860 dikey, tetris benzeri blok oyununu Godot 4 ile tamamlamak.
Kredi bütçesi: 5 USD. Her faz sonunda harcanan kredi kayda geçer.

## Çalışma düzeni

- Haftada 2 veya 3 sabit blok, her biri 60-90 dakika.
- Her blok sonunda kabul kriterini kontrol et: "Bu blok bitince ... oynanabilir olmalı."
- Bir fazı bitirmeden sonrakine geçme.

## Fazlar

### [X] Faz 0 - Kurulum

- Godot 4 projesi aç, pencere boyutu 480x860, dikey.
- Main.tscn kök sahnesi, arka plan #0D1A38.
- Kabul: Proje açılıyor, boş koyu ekran görünüyor.

### [ ] Faz 1 - Izgara çizimi

- Board.gd: 10x20 boş ızgara çiz.
- Kabul: Ekranda ortalanmış ızgara görünüyor.

### [ ] Faz 2 - Parça üretimi ve düşme

- Pieces.gd ile 7 parça tanımı.
- Rastgele parça spawn, Timer ile otomatik düşme.
- Kabul: Parça yukarıdan aşağı düşüyor.

### [ ] Faz 3 - Sağ/sol hareket ve hızlı düşüş

- Yön tuşları ile hareket, aşağı tuşu ile hızlı düşüş.
- Kabul: Parça duvara kadar hareket edebiliyor ve duvarda duruyor.

### [ ] Faz 4 - Döndürme ve çarpışma

- Saat yönünde döndürme, basit wall kick.
- Kabul: Her parça döner, duvar ve diğer bloklara girmez.

### [ ] Faz 5 - Yerleşme

- Parça dibe veya başka bloğa değince ızgaraya kaydolur.
- Yeni parça spawn olur.
- Kabul: Yerleşen bloklar kalıcı, üst üste biniyorlar.

### [ ] Faz 6 - Satır temizleme ve puan

- Dolu satırlar silinir, üsttekiler iner, puan eklenir.
- Kabul: 1-4 satır temizliği doğru puanı veriyor.

### [ ] Faz 7 - Oyun bitti ve yeniden başlatma

- Oyun bitti ekranı (gameover.svg referansı), skor gösterimi.
- Tekrar oyna düğmesi.
- Kabul: Oyun bitince ekran çıkıyor, tekrar başlatılabiliyor.

### [ ] Faz 8 - Ana menü

- menu.svg referansıyla başlat ve çıkış düğmeleri.
- Kabul: Menüden oyuna geçiş ve dönüş çalışıyor.

### [ ] Faz 9 - Seviye ve hız

- Her 10 satırda seviye artışı, düşme hızı azalır.
- Kabul: Seviye ekranda görünüyor, hız artıyor.

### [ ] Faz 10 - Tema (sonra)

- dark.svg ve light.svg arasında geçiş.
- Kabul: Tema değişince renkler doğru değişiyor.

### [ ] Faz 11 - Ses (opsiyonel)

- Yerleşme, satır temizleme ve oyun bitti sesleri.
- Kabul: Sesler doğru olaylarda çalıyor, kapatılabiliyor.

## Kapsam dışı (şimdilik yapma)

- Çok oyunculu mod, online skor tablosu
- Mobil dağıtım (APK/AAB) ayarları
- Hesap, reklam, satın alma

## Gidişat günlüğü

- [Tarih] Faz ** tamamlandı. Harcanan kredi: ** USD. Takıldığım nokta: \_\_.
- [Tarih] Faz ** tamamlandı. Harcanan kredi: ** USD. Takıldığım nokta: \_\_.

## Bütçe takibi

- Toplam: 5.00 USD
- Harcanan: 0.00 USD
- Kalan: 5.00 USD
