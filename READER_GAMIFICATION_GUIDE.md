# 🎮 Reader Gamification System - Complete Guide

## 📋 Overview

Sistem gamification untuk Reader dirancang untuk membuat pengalaman membaca lebih engaging dan rewarding. Reader bisa earn XP, level up, complete missions, collect badges, dan compete di leaderboard!

---

## 🎯 Table of Contents

1. [XP & Leveling System](#xp--leveling-system)
2. [Mission System](#mission-system)
3. [Badge System](#badge-system)
4. [Leaderboard & Ranking](#leaderboard--ranking)
5. [Supporter Level System](#supporter-level-system)
6. [Daily Reward System](#daily-reward-system)
7. [Season System](#season-system)

---

## 🌟 XP & Leveling System

### **Apa itu XP?**

XP (Experience Points) adalah poin yang dikumpulkan reader melalui berbagai aktivitas engagement. Semakin banyak XP, semakin tinggi level!

### **Cara Mendapat XP**

#### **Engagement Activities** (Pure Engagement - No Coins)

| Activity             | XP Earned | Daily Cap | Notes                            |
| -------------------- | --------- | --------- | -------------------------------- |
| 💬 **Comment**       | 5 XP      | 50 XP/day | Max 10 comments/day              |
| ❤️ **Like Received** | 2 XP      | 40 XP/day | When someone likes your comment  |
| 🚪 **Daily Login**   | 5 XP      | 5 XP/day  | Once per day                     |
| 📖 **Read Episode**  | 3 XP      | 30 XP/day | Complete episode (100% progress) |

#### **Mission Rewards**

- 🎯 Daily missions: 20-50 XP each
- 📅 Weekly missions: 100-200 XP each
- 🏆 Lifetime missions: 50-500 XP each

#### **Daily Reward**

- 🎁 Streak-based: 10-50 XP
- Day 1: 10 XP
- Day 2: 20 XP
- Day 3: 30 XP
- Day 4: 40 XP
- Day 5+: 50 XP

### **Daily XP Caps** (Anti-Farming)

Sistem menggunakan **daily caps** untuk prevent farming:

```
📊 Daily XP Limits:
- Comment: 50 XP max (10 comments × 5 XP)
- Like Received: 40 XP max (20 likes × 2 XP)
- Daily Login: 5 XP max (once per day)
- Reading: 30 XP max (10 episodes × 3 XP)

Total Max: ~125 XP/day from activities
+ Missions: ~200 XP/day
+ Daily Reward: ~50 XP/day
= ~375 XP/day maximum
```

### **Level System**

#### **Level Calculation**

```php
Level = floor(sqrt(total_xp / 100))

Examples:
- 100 XP = Level 1
- 400 XP = Level 2
- 900 XP = Level 3
- 1,600 XP = Level 4
- 10,000 XP = Level 10
- 40,000 XP = Level 20
- 100,000 XP = Level 31
```

#### **Level Range**

- **Minimum**: Level 0 (0 XP)
- **Maximum**: Level 100 (1,000,000 XP)

#### **Level Up Rewards**

- 🎉 Notification
- 🏅 Badge (at certain milestones)
- 💰 Coins bonus (optional)

#### **Level Display**

- Profile screen: Large level badge
- Leaderboard: Level indicator
- Comments: Level badge next to name

---

## 🎯 Mission System

### **Mission Types**

#### **1. Daily Missions** (Reset 00:00 setiap hari)

| Mission              | Target     | XP Reward | Coin Reward |
| -------------------- | ---------- | --------- | ----------- |
| 📖 **Read Episodes** | 5 episodes | 50 XP     | 10 coins    |
| ❤️ **Like Episodes** | 5 likes    | 30 XP     | 5 coins     |
| 💬 **Comment**       | 3 comments | 40 XP     | 5 coins     |
| 👥 **Follow Author** | 1 author   | 20 XP     | 5 coins     |

**Total Daily**: 140 XP + 25 coins

#### **2. Weekly Missions** (Reset setiap Senin 00:00)

| Mission                | Target      | XP Reward | Coin Reward |
| ---------------------- | ----------- | --------- | ----------- |
| 📚 **Read Episodes**   | 25 episodes | 200 XP    | 50 coins    |
| 💬 **Comment**         | 15 comments | 150 XP    | 30 coins    |
| 👥 **Follow Authors**  | 5 authors   | 100 XP    | 20 coins    |
| 🔖 **Bookmark Series** | 5 series    | 100 XP    | 20 coins    |

**Total Weekly**: 550 XP + 120 coins

#### **3. Lifetime Missions** (One-time achievements)

| Mission                   | Target        | XP Reward | Coin Reward |
| ------------------------- | ------------- | --------- | ----------- |
| 📖 **Read 100 Episodes**  | 100 episodes  | 500 XP    | 100 coins   |
| 📖 **Read 500 Episodes**  | 500 episodes  | 2000 XP   | 500 coins   |
| 📖 **Read 1000 Episodes** | 1000 episodes | 5000 XP   | 1000 coins  |
| 💬 **Comment 100 Times**  | 100 comments  | 300 XP    | 50 coins    |
| 👥 **Follow 50 Authors**  | 50 authors    | 200 XP    | 50 coins    |
| 🔖 **Bookmark 50 Series** | 50 series     | 200 XP    | 50 coins    |
| 💰 **Spend 500 Coins**    | 500 coins     | 100 XP    | 0 coins     |

**Total Lifetime**: 8,300 XP + 1,750 coins

### **Mission Progress Tracking**

#### **Auto-Tracking**

Missions automatically track progress when you:

- Read episode → Tracks read missions
- Comment → Tracks comment missions
- Like → Tracks like missions
- Follow → Tracks follow missions
- Bookmark → Tracks bookmark missions
- Spend coins → Tracks spending missions

#### **Progress Display**

```
Mission Card:
┌─────────────────────────────────┐
│ 📖 Read 5 Episodes              │
│ Complete 5 episodes today       │
│                                 │
│ Progress: 3/5                   │
│ [████████░░░░░░░░] 60%         │
│                                 │
│ Reward: 50 XP + 10 coins        │
│ [Claim] (when completed)        │
└─────────────────────────────────┘
```

#### **Mission States**

- **Active**: In progress, can be completed
- **Completed**: Target reached, ready to claim
- **Claimed**: Reward already claimed
- **Locked**: Not yet available (future feature)

### **Claiming Rewards**

#### **Manual Claim**

- Tap "Claim" button when mission completed
- Rewards added immediately
- Notification sent

#### **Auto-Claim** (Optional)

- Enable in settings
- Rewards claimed automatically when completed
- Still get notification

---

## 🏅 Badge System

### **Badge Categories**

#### **1. Reader Badges** (Reading-related)

| Badge                 | Requirement        | Rarity    | Icon |
| --------------------- | ------------------ | --------- | ---- |
| 📖 **First Read**     | Read 1 episode     | Common    | 📖   |
| 📚 **Bookworm**       | Read 10 episodes   | Common    | 📚   |
| 📕 **Avid Reader**    | Read 50 episodes   | Rare      | 📕   |
| 📗 **Reading Master** | Read 100 episodes  | Epic      | 📗   |
| 📘 **Reading Legend** | Read 500 episodes  | Legendary | 📘   |
| 📙 **Reading God**    | Read 1000 episodes | Legendary | 📙   |

#### **2. Social Badges** (Interaction-related)

| Badge                    | Requirement       | Rarity | Icon |
| ------------------------ | ----------------- | ------ | ---- |
| 💬 **First Comment**     | Post 1 comment    | Common | 💬   |
| 🗨️ **Commentator**       | Post 10 comments  | Common | 🗨️   |
| 💭 **Discussion Master** | Post 100 comments | Rare   | 💭   |
| 👥 **First Follow**      | Follow 1 author   | Common | 👥   |
| 👫 **Social Butterfly**  | Follow 5 authors  | Common | 👫   |
| 👬 **Community Leader**  | Follow 20 authors | Rare   | 👬   |
| 👨‍👩‍👧‍👦 **Super Follower**    | Follow 50 authors | Epic   | 👨‍👩‍👧‍👦   |

#### **3. Collector Badges** (Collection-related)

| Badge                   | Requirement          | Rarity | Icon |
| ----------------------- | -------------------- | ------ | ---- |
| 🔖 **First Bookmark**   | Bookmark 1 series    | Common | 🔖   |
| 📑 **Collector**        | Bookmark 10 series   | Common | 📑   |
| 📚 **Library Master**   | Bookmark 50 series   | Rare   | 📚   |
| 📖 **First Collection** | Create 1 collection  | Common | 📖   |
| 📚 **Organizer**        | Create 5 collections | Rare   | 📚   |

#### **4. Supporter Badges** (Spending-related)

| Badge                      | Requirement       | Rarity    | Icon |
| -------------------------- | ----------------- | --------- | ---- |
| 🥉 **Bronze Supporter**    | Spend 100 coins   | Common    | 🥉   |
| 🥈 **Silver Supporter**    | Spend 500 coins   | Rare      | 🥈   |
| 🥇 **Gold Supporter**      | Spend 1000 coins  | Epic      | 🥇   |
| 💎 **Diamond Supporter**   | Spend 2000 coins  | Epic      | 💎   |
| 💠 **Platinum Supporter**  | Spend 5000 coins  | Legendary | 💠   |
| 👑 **Legendary Supporter** | Spend 10000 coins | Legendary | 👑   |

#### **5. Special Badges** (Event/Achievement)

| Badge                  | Requirement                            | Rarity    | Icon |
| ---------------------- | -------------------------------------- | --------- | ---- |
| 🎉 **Early Adopter**   | Join in beta                           | Rare      | 🎉   |
| 🎊 **Anniversary**     | 1 year member                          | Rare      | 🎊   |
| 🏆 **Top 10 Global**   | Reach top 10 leaderboard               | Epic      | 🏆   |
| 👑 **Season Champion** | Win season #1                          | Legendary | 👑   |
| ⭐ **Perfect Week**    | Complete all daily missions for 7 days | Rare      | ⭐   |
| 🔥 **Streak Master**   | 30-day login streak                    | Epic      | 🔥   |

### **Badge Rarity Levels**

```
Common (White):     Easy to get, basic achievements
Rare (Blue):        Moderate effort required
Epic (Purple):      Significant achievement
Legendary (Gold):   Extremely rare, top-tier
```

### **Badge Display**

#### **Profile Showcase**

- Top 3 badges displayed prominently
- Can pin/unpin badges (coming soon)
- Auto-pin highest rarity badges

#### **Badge Collection Screen**

- Grid view of all badges
- Earned badges: Full color
- Locked badges: Grayscale with lock icon
- Progress indicator for progressive badges

#### **Badge Detail**

```
Badge Modal:
┌─────────────────────────────────┐
│         📚 (Large Icon)         │
│                                 │
│      Reading Master             │
│                                 │
│  Read 100 episodes to earn      │
│  this epic badge!               │
│                                 │
│  Progress: 75/100               │
│  [████████████░░░░] 75%        │
│                                 │
│  Rarity: Epic                   │
│  Earned by: 1,234 readers       │
│  Earned on: 2026-04-15          │
└─────────────────────────────────┘
```

### **Badge Earning**

#### **Auto-Award**

Badges automatically awarded when:

- Reach milestone (read X episodes)
- Complete achievement (first comment)
- Spend threshold (500 coins)

#### **Notification**

```
🏆 Badge Earned!
You got "Reading Master" badge!
Tap to view your collection.
```

---

## 🏆 Leaderboard & Ranking

### **Leaderboard Types**

#### **1. Global XP Leaderboard**

- **Ranking by**: Total XP earned in current season
- **Updates**: Every 5 minutes
- **Display**: Top 100 readers
- **Rewards**: Top 10 get bonus coins at season end

#### **2. Top Supporters Leaderboard**

- **Ranking by**: Total coins spent in current season
- **Updates**: Real-time
- **Display**: Top 50 supporters
- **Rewards**: Recognition + special badge

#### **3. Per-Author Supporters**

- **Ranking by**: Coins spent on specific author
- **Display**: Top 10 supporters per author
- **Shown**: On author profile page
- **Recognition**: Listed as top supporter

### **Leaderboard Display**

#### **Top 3 Podium** (Special Display)

```
        🥈 #2
    ┌─────────┐
    │  Avatar │
    │  Name   │
    │ 15,234  │
    └─────────┘

🥇 #1                    🥉 #3
┌─────────┐          ┌─────────┐
│  Avatar │          │  Avatar │
│  Name   │          │  Name   │
│ 23,456  │          │ 12,345  │
└─────────┘          └─────────┘
```

#### **Rank 4+ List**

```
┌─────────────────────────────────┐
│ 4  👤 Username      10,234 XP   │
│ 5  👤 Username       9,876 XP   │
│ 6  👤 Username       8,765 XP   │
│ 7  👤 Username       7,654 XP   │
│ ...                             │
│ 25 👤 You            3,456 XP   │ ← Highlighted
│ ...                             │
└─────────────────────────────────┘
```

### **Your Rank Card**

```
┌─────────────────────────────────┐
│         Your Ranking            │
│                                 │
│  Rank: #25 / 1,234 readers      │
│  XP: 3,456                      │
│                                 │
│  Next rank: #24 (3,567 XP)      │
│  Gap: 111 XP                    │
│                                 │
│  [████████████░░░░] 96%        │
└─────────────────────────────────┘
```

### **Season Rewards**

#### **Top 10 Global XP**

| Rank  | Reward                        |
| ----- | ----------------------------- |
| 🥇 #1 | 1,000 coins + Legendary badge |
| 🥈 #2 | 750 coins + Epic badge        |
| 🥉 #3 | 500 coins + Epic badge        |
| #4-5  | 300 coins + Rare badge        |
| #6-10 | 200 coins + Rare badge        |

#### **Top 10 Supporters**

| Rank  | Reward                        |
| ----- | ----------------------------- |
| 🥇 #1 | Special "Top Supporter" badge |
| 🥈 #2 | Special "Top Supporter" badge |
| 🥉 #3 | Special "Top Supporter" badge |
| #4-10 | Recognition badge             |

---

## 💎 Supporter Level System

### **Supporter Levels** (Lifetime Spending)

| Level            | Min Spend    | Badge | Benefits                            |
| ---------------- | ------------ | ----- | ----------------------------------- |
| 🥉 **Bronze**    | 0 coins      | 🥉    | Basic supporter                     |
| 🥈 **Silver**    | 500 coins    | 🥈    | Silver badge                        |
| 🥇 **Gold**      | 1,000 coins  | 🥇    | Gold badge                          |
| 💎 **Diamond**   | 2,000 coins  | 💎    | Diamond badge + priority support    |
| 💠 **Platinum**  | 5,000 coins  | 💠    | Platinum badge + exclusive features |
| 👑 **Legendary** | 10,000 coins | 👑    | Legendary badge + VIP status        |

### **Lifetime Spending Tracking**

```
Your Supporter Status:
┌─────────────────────────────────┐
│  💎 Diamond Supporter           │
│                                 │
│  Lifetime Spend: 2,345 coins    │
│                                 │
│  Next Level: Platinum (5,000)   │
│  Progress: 2,345 / 5,000        │
│  [████████░░░░░░░░] 47%        │
│                                 │
│  Gap: 2,655 coins               │
└─────────────────────────────────┘
```

### **Supporter Benefits**

#### **Visual Recognition**

- Badge displayed on profile
- Badge shown in comments
- Listed in top supporters

#### **Exclusive Features** (Platinum+)

- Priority customer support
- Early access to new features
- Exclusive events (coming soon)
- Special profile frame (coming soon)

---

## 🎁 Daily Reward System

### **Daily Reward Mechanics**

#### **Streak System**

```
Day 1:  10 XP + 0 coins
Day 2:  20 XP + 0 coins
Day 3:  30 XP + 0 coins
Day 4:  40 XP + 0 coins
Day 5+: 50 XP + 0 coins (max)
```

#### **Streak Rules**

- ✅ Claim once per day (00:00 - 23:59)
- ✅ Streak continues if claimed daily
- ❌ Streak resets if miss a day
- ✅ Can claim anytime during the day

### **Daily Reward UI**

#### **Wallet Screen**

```
┌─────────────────────────────────┐
│      Daily Reward 🎁            │
│                                 │
│  Current Streak: 5 days 🔥      │
│                                 │
│  Today's Reward:                │
│  50 XP + 0 coins                │
│                                 │
│  [Claim Reward]                 │
│                                 │
│  Week Calendar:                 │
│  M  T  W  T  F  S  S           │
│  ✅ ✅ ✅ ✅ ✅ ⬜ ⬜          │
└─────────────────────────────────┘
```

#### **Claimed State**

```
┌─────────────────────────────────┐
│      Daily Reward 🎁            │
│                                 │
│  ✅ Claimed Today!              │
│                                 │
│  Current Streak: 5 days 🔥      │
│                                 │
│  Next Reward: 50 XP             │
│  Available in: 8h 23m           │
│                                 │
│  Week Calendar:                 │
│  M  T  W  T  F  S  S           │
│  ✅ ✅ ✅ ✅ ✅ ⬜ ⬜          │
└─────────────────────────────────┘
```

### **Streak Bonuses**

#### **Milestone Rewards**

- **7-day streak**: +50 bonus XP
- **14-day streak**: +100 bonus XP + 50 coins
- **30-day streak**: +500 bonus XP + 200 coins + "Streak Master" badge

---

## 🌊 Season System

### **Season Overview**

#### **What is a Season?**

- Time-limited competitive period
- Leaderboards reset each season
- Exclusive rewards for top performers
- Typically 3 months duration

#### **Season Info**

```
┌─────────────────────────────────┐
│      Season 1: Genesis          │
│                                 │
│  Duration: Jan 1 - Mar 31       │
│  Time Remaining: 45 days        │
│                                 │
│  Your Stats:                    │
│  - Rank: #25                    │
│  - XP: 3,456                    │
│  - Coins Spent: 234             │
└─────────────────────────────────┘
```

### **Season Leaderboards**

#### **1. Global XP**

- Tracks XP earned during season
- Resets at season start
- Top 10 get rewards

#### **2. Top Supporters**

- Tracks coins spent during season
- Resets at season start
- Recognition for top spenders

#### **3. Top Authors**

- Tracks coins earned by authors
- Resets at season start
- Author-specific leaderboard

### **Season Rewards**

#### **End of Season**

- Top 10 Global XP: Coins + badges
- Top 10 Supporters: Special badges
- All participants: Participation badge
- Stats archived for history

#### **Season History**

```
Past Seasons:
┌─────────────────────────────────┐
│ Season 1: Genesis               │
│ Your Rank: #25                  │
│ XP Earned: 3,456                │
│ Reward: Participation Badge     │
└─────────────────────────────────┘
```

---

## 📊 Statistics Tracking

### **Personal Stats**

#### **Reading Stats**

- Total episodes read
- Total reading time
- Favorite genres
- Reading streak
- Completion rate

#### **Engagement Stats**

- Total comments posted
- Total likes given
- Total bookmarks
- Total collections created
- Total authors followed

#### **Progression Stats**

- Current level
- Total XP earned
- Current rank
- Badges earned (X/30)
- Missions completed

#### **Economy Stats**

- Total coins earned
- Total coins spent
- Lifetime spending
- Supporter level
- Top-up history

### **Stats Display**

```
Your Statistics:
┌─────────────────────────────────┐
│  📖 Reading                     │
│  - Episodes Read: 234           │
│  - Reading Time: 45h 23m        │
│  - Completion Rate: 87%         │
│                                 │
│  💬 Engagement                  │
│  - Comments: 123                │
│  - Likes Given: 456             │
│  - Bookmarks: 34                │
│                                 │
│  🏆 Progression                 │
│  - Level: 15                    │
│  - Total XP: 22,500             │
│  - Rank: #25                    │
│  - Badges: 18/30                │
│                                 │
│  💰 Economy                     │
│  - Coins Earned: 1,234          │
│  - Coins Spent: 567             │
│  - Supporter: 💎 Diamond        │
└─────────────────────────────────┘
```

---

## 🎯 Optimization Tips

### **Maximize XP Earning**

#### **Daily Routine** (375 XP/day max)

1. ✅ Login daily (5 XP)
2. ✅ Claim daily reward (10-50 XP)
3. ✅ Read 10 episodes (30 XP)
4. ✅ Post 10 comments (50 XP)
5. ✅ Get 20 likes on comments (40 XP)
6. ✅ Complete all daily missions (140 XP)
7. ✅ Complete weekly missions (550 XP/week)

#### **Weekly Goals**

- Complete all daily missions every day
- Complete all weekly missions
- Maintain login streak
- Engage with community

#### **Long-term Goals**

- Complete all lifetime missions
- Collect all badges
- Reach top 10 leaderboard
- Achieve Legendary supporter level

### **Efficient Coin Spending**

#### **Priority Spending**

1. **Premium episodes** from favorite authors
2. **Tips** to support authors you love
3. **Save** for future premium content

#### **Earning Coins**

- Complete missions (daily/weekly)
- Leaderboard rewards (top 10)
- Daily reward streak bonuses
- Top-up (coming soon)

---

## 🎮 Gamification Summary

### **Core Systems**

| System              | Purpose      | Key Metrics                 |
| ------------------- | ------------ | --------------------------- |
| **XP & Leveling**   | Progression  | Level 0-100, XP earned      |
| **Missions**        | Daily goals  | 3 types, 15+ missions       |
| **Badges**          | Achievements | 30+ badges, 4 rarities      |
| **Leaderboard**     | Competition  | 3 types, season-based       |
| **Supporter Level** | Recognition  | 6 levels, lifetime spend    |
| **Daily Reward**    | Retention    | Streak-based, XP rewards    |
| **Seasons**         | Time-limited | 3 months, exclusive rewards |

### **Engagement Loop**

```
Read Content → Earn XP → Level Up → Unlock Badges
     ↑                                      ↓
Complete Missions ← Claim Rewards ← Check Progress
     ↑                                      ↓
Compete in Leaderboard ← Earn Coins ← Support Authors
```

### **Reward Tiers**

```
Casual Reader:
- Read episodes
- Earn XP
- Level up
- Collect common badges

Active Reader:
- Complete daily missions
- Maintain streak
- Collect rare badges
- Reach top 100 leaderboard

Dedicated Reader:
- Complete all missions
- Collect all badges
- Reach top 10 leaderboard
- Achieve epic/legendary badges

Super Supporter:
- Spend 1000+ coins
- Support multiple authors
- Reach Diamond+ level
- Get exclusive recognition
```

---

## 💡 Best Practices

### **For Maximum Engagement**

1. ✅ Login daily to maintain streak
2. ✅ Complete all daily missions
3. ✅ Read and comment regularly
4. ✅ Support favorite authors
5. ✅ Collect all badges
6. ✅ Compete in leaderboard
7. ✅ Participate in seasons

### **For Efficient Progression**

1. ✅ Focus on daily missions first
2. ✅ Prioritize high-XP activities
3. ✅ Maintain daily reward streak
4. ✅ Complete lifetime missions gradually
5. ✅ Engage with community
6. ✅ Track your progress regularly

### **For Community Building**

1. ✅ Comment thoughtfully
2. ✅ Support authors with tips
3. ✅ Share favorite series
4. ✅ Follow active authors
5. ✅ Participate in discussions
6. ✅ Help new readers

---

## 🚀 Future Enhancements

### **Planned Features**

- [ ] Achievement system expansion
- [ ] Guild/team system
- [ ] PvP challenges
- [ ] Special events
- [ ] Limited-time missions
- [ ] Exclusive seasonal badges
- [ ] Referral rewards
- [ ] Social features (friends, groups)
- [ ] Custom challenges
- [ ] Leaderboard tournaments

---

**Reader gamification system dirancang untuk membuat reading experience lebih fun, engaging, dan rewarding! Setiap aktivitas dihargai, setiap pencapaian dirayakan!** 🎮🏆✨
