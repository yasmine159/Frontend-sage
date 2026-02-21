import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  // ── Fake data ─────────────────────────────────────────────
  final List<Map<String, dynamic>> _uploadStats = [
    {'day': 'Mon', 'uploads': 8,  'success': 7,  'failed': 1},
    {'day': 'Tue', 'uploads': 12, 'success': 11, 'failed': 1},
    {'day': 'Wed', 'uploads': 5,  'success': 5,  'failed': 0},
    {'day': 'Thu', 'uploads': 15, 'success': 13, 'failed': 2},
    {'day': 'Fri', 'uploads': 10, 'success': 10, 'failed': 0},
    {'day': 'Sat', 'uploads': 3,  'success': 3,  'failed': 0},
    {'day': 'Sun', 'uploads': 6,  'success': 5,  'failed': 1},
  ];

  final List<Map<String, dynamic>> _templateUsage = [
    {'name': 'MES01', 'downloads': 34, 'color': Color(0xFF1e3a8a), 'percent': 0.75},
    {'name': 'MES02', 'downloads': 22, 'color': Color(0xFF0ea5e9), 'percent': 0.49},
    {'name': 'MES03', 'downloads': 18, 'color': Color(0xFF10b981), 'percent': 0.40},
    {'name': 'MES04', 'downloads': 11, 'color': Color(0xFFf59e0b), 'percent': 0.24},
    {'name': 'MES05', 'downloads': 6,  'color': Color(0xFF8b5cf6), 'percent': 0.13},
  ];

  final List<Map<String, dynamic>> _recentReports = [
    {
      'title':  'Monthly Upload Summary',
      'date':   'Feb 10, 2026',
      'type':   'Upload',
      'status': 'Ready',
      'size':   '245 KB',
      'icon':   Icons.cloud_upload_outlined,
      'color':  Color(0xFF0ea5e9),
    },
    {
      'title':  'Template Usage Report',
      'date':   'Feb 08, 2026',
      'type':   'Template',
      'status': 'Ready',
      'size':   '132 KB',
      'icon':   Icons.description_outlined,
      'color':  Color(0xFF1e3a8a),
    },
    {
      'title':  'Processing Errors Log',
      'date':   'Feb 06, 2026',
      'type':   'Error',
      'status': 'Ready',
      'size':   '89 KB',
      'icon':   Icons.error_outline,
      'color':  Color(0xFFef4444),
    },
    {
      'title':  'User Activity Report',
      'date':   'Feb 01, 2026',
      'type':   'Activity',
      'status': 'Processing',
      'size':   '—',
      'icon':   Icons.people_outline,
      'color':  Color(0xFF10b981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop   = MediaQuery.of(context).size.width >= 1024;

    return Column(
      children: [
        // ── Header with period selector ──────────────────────
        _buildHeader(context, isDesktop),

        // ── Body ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI row
                _buildKpiRow(context, isDesktop),
                SizedBox(height: 28),

                // Charts row
                isDesktop
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildUploadChart(context)),
                    SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildTemplateUsage(context)),
                  ],
                )
                    : Column(
                  children: [
                    _buildUploadChart(context),
                    SizedBox(height: 20),
                    _buildTemplateUsage(context),
                  ],
                ),

                SizedBox(height: 28),

                // Recent reports table
                _buildRecentReports(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Period chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Export button
          OutlinedButton.icon(
            onPressed: () => _showExportDialog(context),
            icon: Icon(Icons.download_outlined, size: 16),
            label: Text('Export'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Row ─────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context, bool isDesktop) {
    final kpis = [
      {
        'label':  'Total Uploads',
        'value':  '59',
        'sub':    '+12% vs last period',
        'icon':   Icons.cloud_upload_outlined,
        'color':  Color(0xFF0ea5e9),
        'bg':     Color(0xFFe0f2fe),
        'trend':  true,
      },
      {
        'label':  'Success Rate',
        'value':  '93%',
        'sub':    '+2% vs last period',
        'icon':   Icons.check_circle_outline,
        'color':  Color(0xFF10b981),
        'bg':     Color(0xFFd1fae5),
        'trend':  true,
      },
      {
        'label':  'Failed',
        'value':  '4',
        'sub':    '-3 vs last period',
        'icon':   Icons.cancel_outlined,
        'color':  Color(0xFFef4444),
        'bg':     Color(0xFFfee2e2),
        'trend':  false,
      },
      {
        'label':  'Templates Used',
        'value':  '5',
        'sub':    'All models active',
        'icon':   Icons.description_outlined,
        'color':  Color(0xFF1e3a8a),
        'bg':     Color(0xFFdbeafe),
        'trend':  true,
      },
    ];

    if (isDesktop) {
      return Row(
        children: kpis.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < kpis.length - 1 ? 16 : 0),
              child: _kpiCard(context, e.value),
            ),
          );
        }).toList(),
      );
    }

    return Column(children: [
      Row(children: [
        Expanded(child: _kpiCard(context, kpis[0])),
        SizedBox(width: 12),
        Expanded(child: _kpiCard(context, kpis[1])),
      ]),
      SizedBox(height: 12),
      Row(children: [
        Expanded(child: _kpiCard(context, kpis[2])),
        SizedBox(width: 12),
        Expanded(child: _kpiCard(context, kpis[3])),
      ]),
    ]);
  }

  Widget _kpiCard(BuildContext context, Map<String, dynamic> k) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: k['bg'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(k['icon'], color: k['color'], size: 18),
              ),
              Icon(
                (k['trend'] as bool) ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: (k['trend'] as bool) ? Color(0xFF10b981) : Color(0xFFef4444),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(k['value'],
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          SizedBox(height: 2),
          Text(k['label'],
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface)),
          SizedBox(height: 4),
          Text(k['sub'],
              style: TextStyle(
                  fontSize: 11,
                  color: (k['trend'] as bool)
                      ? Color(0xFF10b981)
                      : Color(0xFFef4444))),
        ],
      ),
    );
  }

  // ── Upload bar chart ────────────────────────────────────────
  Widget _buildUploadChart(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxVal      = _uploadStats
        .map((e) => e['uploads'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Activity',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    SizedBox(height: 2),
                    Text('Daily uploads this week',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              // Legend
              Row(children: [
                _legendDot(Color(0xFF1e3a8a), 'Success'),
                SizedBox(width: 12),
                _legendDot(Color(0xFFef4444), 'Failed'),
              ]),
            ],
          ),
          SizedBox(height: 24),

          // Bars
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _uploadStats.map((day) {
                final total   = (day['uploads'] as int).toDouble();
                final success = (day['success'] as int).toDouble();
                final failed  = (day['failed']  as int).toDouble();
                final barH    = (total / maxVal) * 140;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Stacked bar
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                          child: Column(
                            children: [
                              // Failed (top)
                              if (failed > 0)
                                Flexible(
                                  flex: failed.toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFef4444),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ),
                                ),
                              // Success (bottom)
                              Flexible(
                                flex: success.toInt(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1e3a8a),
                                    borderRadius: failed == 0
                                        ? BorderRadius.vertical(top: Radius.circular(6))
                                        : BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(day['day'],
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF64748b))),
      ],
    );
  }

  // ── Template usage ──────────────────────────────────────────
  Widget _buildTemplateUsage(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Template Usage',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          SizedBox(height: 2),
          Text('Downloads per template',
              style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5))),
          SizedBox(height: 22),
          ..._templateUsage.map((t) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Template badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (t['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(t['name'],
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: t['color'] as Color)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t['name'],
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface)),
                              Text('${t['downloads']} downloads',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withOpacity(0.5))),
                            ],
                          ),
                          SizedBox(height: 6),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: t['percent'] as double,
                              backgroundColor: (t['color'] as Color).withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(t['color'] as Color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Recent reports list ─────────────────────────────────────
  Widget _buildRecentReports(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Generated Reports',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_recentReports.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary)),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Generate'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Report rows
          ..._recentReports.map((r) => _reportRow(context, r)),
        ],
      ),
    );
  }

  Widget _reportRow(BuildContext context, Map<String, dynamic> r) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReady     = r['status'] == 'Ready';

    return InkWell(
      onTap: () => isReady ? _showDownloadSnack(context, r['title']) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (r['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(r['icon'] as IconData, color: r['color'] as Color, size: 20),
            ),
            SizedBox(width: 14),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title'],
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 11, color: colorScheme.onSurface.withOpacity(0.4)),
                      SizedBox(width: 4),
                      Text(r['date'],
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.4))),
                    ],
                  ),
                ],
              ),
            ),

            // Type badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (r['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r['type'],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: r['color'] as Color)),
            ),
            SizedBox(width: 12),

            // Status
            _statusBadge(r['status']),
            SizedBox(width: 12),

            // Size
            Text(r['size'],
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4))),
            SizedBox(width: 12),

            // Download action
            isReady
                ? Icon(Icons.download_outlined,
                color: colorScheme.primary, size: 20)
                : SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFf59e0b))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Ready':
        color = Color(0xFF10b981);
        break;
      case 'Processing':
        color = Color(0xFFf59e0b);
        break;
      default:
        color = Color(0xFF64748b);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  void _showDownloadSnack(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_done, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Downloading: $title')),
          ],
        ),
        backgroundColor: Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download_outlined, color: Color(0xFF1e3a8a)),
            SizedBox(width: 10),
            Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportOption(context, Icons.picture_as_pdf, 'Export as PDF', Color(0xFFef4444)),
            SizedBox(height: 10),
            _exportOption(context, Icons.table_chart_outlined, 'Export as Excel', Color(0xFF10b981)),
            SizedBox(height: 10),
            _exportOption(context, Icons.code, 'Export as CSV', Color(0xFF0ea5e9)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _exportOption(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}