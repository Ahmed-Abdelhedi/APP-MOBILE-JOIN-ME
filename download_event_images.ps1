# PowerShell Script to download free event images from Unsplash
# These are royalty-free images that can be used in your app

$outputFolder = "assets\images\events"

# Create folder if it doesn't exist
if (!(Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force
}

Write-Host "Downloading event images from Unsplash..." -ForegroundColor Cyan
Write-Host ""

# Image URLs from Unsplash (free to use)
$images = @(
    # Sports
    @{ Name = "sports_football.jpg"; Url = "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&q=80" },
    @{ Name = "sports_basketball.jpg"; Url = "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80" },
    @{ Name = "sports_tennis.jpg"; Url = "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&q=80" },
    @{ Name = "sports_running.jpg"; Url = "https://images.unsplash.com/photo-1461896836934- voices-running?w=800&q=80" },
    @{ Name = "sports_cycling.jpg"; Url = "https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=800&q=80" },
    @{ Name = "sports_swimming.jpg"; Url = "https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800&q=80" },
    
    # Gaming
    @{ Name = "gaming_esports.jpg"; Url = "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80" },
    @{ Name = "gaming_console.jpg"; Url = "https://images.unsplash.com/photo-1493711662062-fa541f7f3d24?w=800&q=80" },
    @{ Name = "gaming_pc.jpg"; Url = "https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=800&q=80" },
    @{ Name = "gaming_vr.jpg"; Url = "https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?w=800&q=80" },
    @{ Name = "gaming_board.jpg"; Url = "https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=800&q=80" },
    
    # Nature
    @{ Name = "nature_hiking.jpg"; Url = "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&q=80" },
    @{ Name = "nature_camping.jpg"; Url = "https://images.unsplash.com/photo-1504851149312-7a075b496cc7?w=800&q=80" },
    @{ Name = "nature_beach.jpg"; Url = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80" },
    @{ Name = "nature_mountain.jpg"; Url = "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80" },
    @{ Name = "nature_forest.jpg"; Url = "https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80" },
    @{ Name = "nature_picnic.jpg"; Url = "https://images.unsplash.com/photo-1526401485004-46910ecc8e51?w=800&q=80" },
    
    # Fitness
    @{ Name = "fitness_gym.jpg"; Url = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80" },
    @{ Name = "fitness_yoga.jpg"; Url = "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80" },
    @{ Name = "fitness_crossfit.jpg"; Url = "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80" },
    @{ Name = "fitness_pilates.jpg"; Url = "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80" },
    @{ Name = "fitness_boxing.jpg"; Url = "https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=800&q=80" },
    
    # Culture
    @{ Name = "culture_museum.jpg"; Url = "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=800&q=80" },
    @{ Name = "culture_concert.jpg"; Url = "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&q=80" },
    @{ Name = "culture_cinema.jpg"; Url = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80" },
    @{ Name = "culture_theater.jpg"; Url = "https://images.unsplash.com/photo-1503095396549-807759245b35?w=800&q=80" },
    @{ Name = "culture_art.jpg"; Url = "https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800&q=80" },
    @{ Name = "culture_book.jpg"; Url = "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&q=80" },
    
    # Food
    @{ Name = "food_restaurant.jpg"; Url = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80" },
    @{ Name = "food_brunch.jpg"; Url = "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=800&q=80" },
    @{ Name = "food_cooking.jpg"; Url = "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800&q=80" },
    @{ Name = "food_coffee.jpg"; Url = "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80" },
    @{ Name = "food_bbq.jpg"; Url = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80" },
    @{ Name = "food_wine.jpg"; Url = "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&q=80" },
    
    # General/Party
    @{ Name = "party_celebration.jpg"; Url = "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80" },
    @{ Name = "party_friends.jpg"; Url = "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&q=80" },
    @{ Name = "meetup_group.jpg"; Url = "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&q=80" },
    @{ Name = "workshop_learning.jpg"; Url = "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&q=80" }
)

$successCount = 0
$failCount = 0

foreach ($img in $images) {
    $outputPath = Join-Path $outputFolder $img.Name
    Write-Host "Downloading $($img.Name)..." -NoNewline
    
    try {
        Invoke-WebRequest -Uri $img.Url -OutFile $outputPath -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Download complete!" -ForegroundColor Green
Write-Host "Success: $successCount / $($images.Count)" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images saved to: $outputFolder" -ForegroundColor White
Write-Host ""
Write-Host "Don't forget to run 'flutter pub get' to update assets!" -ForegroundColor Yellow
