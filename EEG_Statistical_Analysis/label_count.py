"""
label_count.py quickly summarizes and visualizes epoch counts and label distributions
from the pipeline's epochs_summary.csv. Produces high-level diagnostics:
    - Total epochs progression (theoretical → after rejection steps)
    - Final-epochs percentage per session
    - Total counts per label type (and OS vs CS comparison)
    - Per-subject label distribution plots
    - Basic descriptive statistics CSV

Inputs (expected columns in epochs_summary.csv):
    - Theoretical_Epochs, Epochs_initial, Epochs_after_events, Epochs_after_visual
    - Subject, Session
    - One column per label variant (naming convention: <label>_os and <label>_cs)
    e.g., 'Baja_el_volumen_os', 'Baja_el_volumen_cs', etc.

Outputs (saved to output_dir):
    - summary_statistics.csv (basic describe() output)
    - epochs_progression.png (bar plot of epoch counts per stage)
    - epochs_final_percentage.png (final % of theoretical per session)
    - total_labels.png (total counts per label type)
    - compare_os_cs.png (OS vs CS grouped bar chart)
    - {Subject}_labels.png (per-subject label distribution plots)

Author:
Mario Lobo (UPM)
Version:
12-11-2025
"""

import pandas as pd
import matplotlib.pyplot as plt
import os

# ========================
# INITIAL CONFIGURATION
# ========================
csv_path = "C:\\Users\\user\\Desktop\\Mario Lobo\\Silent Speech Data Amazon Both\\epochs_summary.csv"  # <-- Change to your CSV file
output_dir = "C:\\Users\\user\\Desktop\\Mario Lobo\\Silent Speech Data Amazon Both\\Study\\EEG_Epochs_Analysis"
os.makedirs(output_dir, exist_ok=True)

# ========================
# LOAD DATA
# ========================
df = pd.read_csv(csv_path)
print("Columns:", df.columns.tolist())
print(f"Total rows: {len(df)}")

# ========================
# BASIC SUMMARY
# ========================
summary = df.describe()
summary.to_csv(os.path.join(output_dir, "summary_statistics.csv"))
print("\nBasic statistics saved to summary_statistics.csv")

# ========================
# EPOCHS PROGRESSION
# ========================
plt.figure(figsize=(8,4))

# Sum across all rows for each stage
df_sum = df[['Theoretical_Epochs', 'Epochs_initial', 'Epochs_after_events', 'Epochs_after_visual']].sum()

# Bar plot
bars = plt.bar(df_sum.index, df_sum.values, color=['blue', 'skyblue', 'orange', 'green'])

# Add exact value above each bar
for bar, val in zip(bars, df_sum.values):
    plt.text(bar.get_x() + bar.get_width()/2, val + 0.5, str(int(val)),
             ha='center', va='bottom', fontsize=10)

plt.title("Total Number of Epochs at Each Stage")
plt.ylabel("Epoch Count")
plt.grid(True)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "epochs_progression.png"))
plt.close()

# ========================
# FINAL EPOCHS PERCENTAGE
# ========================
df['Percent_final'] = (df['Epochs_after_visual'] / df['Theoretical_Epochs']) * 100

# Create a short label for Subject + Session including NN prefix if present
df['SubSess_short'] = df.apply(
    lambda row: row['Subject'][:2] + "_" + row['Subject'][-2:] + "_" + row['Session'][-2:]
    if row['Subject'].startswith("NN")
    else row['Subject'][-2:] + "_" + row['Session'][-2:],
    axis=1
)

plt.figure(figsize=(15,8))
bars = plt.bar(df['SubSess_short'], df['Percent_final'])

# Add the exact value above each bar
for bar, val in zip(bars, df['Percent_final']):
    plt.text(bar.get_x() + bar.get_width()/2, val + 0.5, str(int(round(val))),
             ha='center', va='bottom', fontsize=10)

plt.xticks(rotation=45)
plt.ylabel("Final Epochs (%)")
plt.title("Final Epochs Percentage by Session")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "epochs_final_percentage.png"))
plt.close()

# ========================
# TOTAL BY LABEL TYPE
# ========================
# Select label columns (those ending in _os or _cs)
label_cols = [c for c in df.columns if c.endswith('_os') or c.endswith('_cs')]

# Total number of each label type
total_labels = df[label_cols].sum().sort_values(ascending=False)

plt.figure(figsize=(10,5))
bars = plt.bar(total_labels.index, total_labels.values)

# Add value above each bar
for bar, val in zip(bars, total_labels.values):
    plt.text(bar.get_x() + bar.get_width()/2, val + 0.5, str(int(val)),
             ha='center', va='bottom', fontsize=10)

plt.title("Total Number of Epochs per Label Type")
plt.ylabel("Total Count")
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "total_labels.png"))
plt.close()

# ========================
# OS vs CS COMPARISON
# ========================

labels_base = list(set([c.replace('_os', '').replace('_cs', '') for c in label_cols]))

os_totals = [df[f"{l}_os"].sum() for l in labels_base]
cs_totals = [df[f"{l}_cs"].sum() for l in labels_base]

compare_df = pd.DataFrame({'OS': os_totals, 'CS': cs_totals}, index=labels_base)

# Plot and get axis
ax = compare_df.plot(kind='bar', figsize=(9,6))

for i, container in enumerate(ax.containers):
    # OS bars
    if i == 0:
        ax.bar_label(container, fmt='%d', padding=2)
    # CS bars (move farther up)
    else:
        ax.bar_label(container, fmt='%d', padding=9)

current_lim = ax.get_ylim()
ax.set_ylim(0, current_lim[1] + 10)

ax.set_title("OS vs CS Comparison per Label Type")
ax.set_ylabel("Total Occurrences")
plt.xticks(rotation=45, ha='right')

plt.tight_layout()
plt.savefig(os.path.join(output_dir, "compare_os_cs.png"))
plt.close()

# ========================
# LABEL DISTRIBUTION PER SUBJECT
# ========================
subjects = df['Subject'].unique()

for subj in subjects:
    subj_df = df[df['Subject'] == subj]
    subj_labels_sum = subj_df[label_cols].sum()
    
    plt.figure(figsize=(8,4))
    subj_labels_sum.plot(kind='bar')
    
    plt.title(f"Label Distribution – Subject {subj}")
    plt.ylabel("Total Count")
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f"{subj}_labels.png"))
    plt.close()

print(f"\n Analysis completed. Plots saved in: {output_dir}")
