#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import sys

if len(sys.argv) != 3:
    print("Usage: python3 analyze_varnish_csv.py <input_csv> <output_png>")
    sys.exit(1)

csv_path = sys.argv[1]
output_path = sys.argv[2]

# Read CSV
df = pd.read_csv(csv_path, parse_dates=["timestamp"])

df["g_bytes_MB"] = df["g_bytes"] / (1024 * 1024)
df["expired_objects"] = df["n_expired"].diff().fillna(0)

# Piirretään
fig, ax1 = plt.subplots(figsize=(14, 7))

# Muistin käyttö
line1, = ax1.plot(df["timestamp"], df["g_bytes_MB"],
                  color="tab:blue", marker='o', label="Memory in use (MiB)")
ax1.set_ylabel("Memory in use (MiB)", color="tab:blue")
ax1.tick_params(axis="y", labelcolor="tab:blue")

# Expired objects
ax2 = ax1.twinx()
ax2.spines["right"]
line2, = ax2.plot(df["timestamp"], df["expired_objects"],
                  color="tab:red", marker='x', label="Expired objects")
ax2.set_ylabel("Expired objects", color="tab:red")
ax2.tick_params(axis="y", labelcolor="tab:red")

# Combined legend
lines = [line1, line2]
labels = [line.get_label() for line in lines]
fig.legend(lines, labels, loc="upper left")

# Look
fig.suptitle("Varnish memory usage and TTL expiry")
plt.xticks(rotation=45)
plt.grid(True)
fig.tight_layout()

# Saving
plt.savefig(output_path, dpi=150)
print(f"Saved plot to {output_path}")
