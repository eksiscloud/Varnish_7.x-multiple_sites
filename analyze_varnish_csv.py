#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import sys

if len(sys.argv) != 2:
    print("Usage: python3 analyze_varnish_csv.py <path_to_csv>")
    sys.exit(1)

csv_path = sys.argv[1]

# Create CSV
df = pd.read_csv(csv_path, parse_dates=["timestamp"])

# Counting variables
df["g_bytes_MB"] = df["g_bytes"] / (1024 * 1024)
df["cumulative_growth_MB"] = (df["c_bytes"] - df["c_freed"]) / (1024 * 1024)
df["expired_objects"] = df["s_expired"].diff().fillna(0)

# Draw the graph
fig, ax1 = plt.subplots(figsize=(14, 7))

ax1.plot(df["timestamp"], df["g_bytes_MB"], color="tab:blue", label="Memory in use (MiB)", marker='o')
ax1.set_ylabel("Memory in use (MiB)", color="tab:blue")
ax1.tick_params(axis="y", labelcolor="tab:blue")

ax2 = ax1.twinx()
ax2.plot(df["timestamp"], df["cumulative_growth_MB"], color="tab:green", label="Net memory growth (MiB)", marker='s')
ax2.set_ylabel("Net memory growth (MiB)", color="tab:green")
ax2.tick_params(axis="y", labelcolor="tab:green")

ax3 = ax1.twinx()
ax3.spines["right"].set_position(("outward", 60))
ax3.plot(df["timestamp"], df["expired_objects"], color="tab:red", label="Expired objects", marker='x')
ax3.set_ylabel("Expired objects", color="tab:red")
ax3.tick_params(axis="y", labelcolor="tab:red")

fig.suptitle("Varnish memory usage, allocation growth and TTL expiry")
fig.tight_layout()
plt.xticks(rotation=45)
plt.grid(True)
plt.show()
