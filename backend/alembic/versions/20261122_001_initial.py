"""Initial AI Guardian schema

Revision ID: 20261122_001
Revises:
"""
from alembic import op
import sqlalchemy as sa

revision = "20261122_001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "scan_history",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("scan_type", sa.String(length=32), nullable=False),
        sa.Column("risk_score", sa.Integer(), nullable=False),
        sa.Column("risk_category", sa.String(length=32), nullable=False),
        sa.Column("indicators", sa.JSON(), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_scan_history_scan_type", "scan_history", ["scan_type"])
    op.create_index("ix_scan_history_risk_category", "scan_history", ["risk_category"])
    op.create_index("ix_scan_history_created_at", "scan_history", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_scan_history_created_at", table_name="scan_history")
    op.drop_index("ix_scan_history_risk_category", table_name="scan_history")
    op.drop_index("ix_scan_history_scan_type", table_name="scan_history")
    op.drop_table("scan_history")
