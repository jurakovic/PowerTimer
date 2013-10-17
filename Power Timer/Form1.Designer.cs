namespace Power_Timer
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.btnStart = new System.Windows.Forms.Button();
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            this.cbAction = new System.Windows.Forms.ComboBox();
            this.tbMin = new System.Windows.Forms.TextBox();
            this.tbHour = new System.Windows.Forms.TextBox();
            this.tbSec = new System.Windows.Forms.TextBox();
            this.secUp = new System.Windows.Forms.Button();
            this.secDown = new System.Windows.Forms.Button();
            this.hourDown = new System.Windows.Forms.Button();
            this.hourUp = new System.Windows.Forms.Button();
            this.minDown = new System.Windows.Forms.Button();
            this.minUp = new System.Windows.Forms.Button();
            this.btnOptions = new System.Windows.Forms.Button();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.button4 = new System.Windows.Forms.Button();
            this.cbWarnZeroTime = new System.Windows.Forms.CheckBox();
            this.btnMinus = new System.Windows.Forms.Button();
            this.btnPlus = new System.Windows.Forms.Button();
            this.tbDefaultTimeDelay = new System.Windows.Forms.TextBox();
            this.comboDefaultAction = new System.Windows.Forms.ComboBox();
            this.label2 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.cbMinimizeToTray = new System.Windows.Forms.CheckBox();
            this.cbRememberWinPos = new System.Windows.Forms.CheckBox();
            this.notifyIcon1 = new System.Windows.Forms.NotifyIcon(this.components);
            this.contextMenuStrip1 = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.toolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripMenuItem();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.groupBox1.SuspendLayout();
            this.contextMenuStrip1.SuspendLayout();
            this.tabControl1.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnStart
            // 
            this.btnStart.Font = new System.Drawing.Font("Tahoma", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.btnStart.Location = new System.Drawing.Point(362, 38);
            this.btnStart.Name = "btnStart";
            this.btnStart.Size = new System.Drawing.Size(119, 26);
            this.btnStart.TabIndex = 6;
            this.btnStart.Text = "START";
            this.btnStart.UseVisualStyleBackColor = true;
            this.btnStart.Click += new System.EventHandler(this.btnStart_Click);
            // 
            // timer1
            // 
            this.timer1.Interval = 1000;
            this.timer1.Tick += new System.EventHandler(this.timer1_Tick);
            // 
            // cbAction
            // 
            this.cbAction.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbAction.Font = new System.Drawing.Font("Tahoma", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.cbAction.FormattingEnabled = true;
            this.cbAction.Items.AddRange(new object[] {
            "Shutdown",
            "Restart",
            "Logoff",
            "Lock",
            "Sleep",
            "Hibernate"});
            this.cbAction.Location = new System.Drawing.Point(363, 8);
            this.cbAction.Name = "cbAction";
            this.cbAction.Size = new System.Drawing.Size(117, 24);
            this.cbAction.TabIndex = 5;
            // 
            // tbMin
            // 
            this.tbMin.Font = new System.Drawing.Font("Tahoma", 29.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.tbMin.Location = new System.Drawing.Point(207, 8);
            this.tbMin.MaxLength = 2;
            this.tbMin.Name = "tbMin";
            this.tbMin.Size = new System.Drawing.Size(72, 55);
            this.tbMin.TabIndex = 3;
            this.tbMin.Text = "00";
            this.tbMin.MouseClick += new System.Windows.Forms.MouseEventHandler(this.textbox_MouseClick);
            this.tbMin.TextChanged += new System.EventHandler(this.textbox_TextChanged);
            this.tbMin.Enter += new System.EventHandler(this.textbox_Enter);
            this.tbMin.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.textbox_KeyPress);
            // 
            // tbHour
            // 
            this.tbHour.Font = new System.Drawing.Font("Tahoma", 29.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.tbHour.Location = new System.Drawing.Point(129, 8);
            this.tbHour.MaxLength = 2;
            this.tbHour.Name = "tbHour";
            this.tbHour.Size = new System.Drawing.Size(72, 55);
            this.tbHour.TabIndex = 2;
            this.tbHour.Text = "01";
            this.tbHour.MouseClick += new System.Windows.Forms.MouseEventHandler(this.textbox_MouseClick);
            this.tbHour.TextChanged += new System.EventHandler(this.textbox_TextChanged);
            this.tbHour.Enter += new System.EventHandler(this.textbox_Enter);
            this.tbHour.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.textbox_KeyPress);
            // 
            // tbSec
            // 
            this.tbSec.Font = new System.Drawing.Font("Tahoma", 29.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.tbSec.Location = new System.Drawing.Point(285, 8);
            this.tbSec.MaxLength = 2;
            this.tbSec.Name = "tbSec";
            this.tbSec.Size = new System.Drawing.Size(72, 55);
            this.tbSec.TabIndex = 4;
            this.tbSec.Text = "00";
            this.tbSec.MouseClick += new System.Windows.Forms.MouseEventHandler(this.textbox_MouseClick);
            this.tbSec.TextChanged += new System.EventHandler(this.textbox_TextChanged);
            this.tbSec.Enter += new System.EventHandler(this.textbox_Enter);
            this.tbSec.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.textbox_KeyPress);
            // 
            // secUp
            // 
            this.secUp.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.secUp.Location = new System.Drawing.Point(340, 9);
            this.secUp.Name = "secUp";
            this.secUp.Size = new System.Drawing.Size(16, 27);
            this.secUp.TabIndex = 11;
            this.secUp.Text = "▲";
            this.secUp.UseVisualStyleBackColor = true;
            this.secUp.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // secDown
            // 
            this.secDown.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.secDown.Location = new System.Drawing.Point(340, 35);
            this.secDown.Name = "secDown";
            this.secDown.Size = new System.Drawing.Size(16, 27);
            this.secDown.TabIndex = 12;
            this.secDown.Text = "▼";
            this.secDown.UseVisualStyleBackColor = true;
            this.secDown.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // hourDown
            // 
            this.hourDown.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.hourDown.Location = new System.Drawing.Point(184, 35);
            this.hourDown.Name = "hourDown";
            this.hourDown.Size = new System.Drawing.Size(16, 27);
            this.hourDown.TabIndex = 8;
            this.hourDown.Text = "▼";
            this.hourDown.UseVisualStyleBackColor = true;
            this.hourDown.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // hourUp
            // 
            this.hourUp.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.hourUp.Location = new System.Drawing.Point(184, 9);
            this.hourUp.Name = "hourUp";
            this.hourUp.Size = new System.Drawing.Size(16, 27);
            this.hourUp.TabIndex = 7;
            this.hourUp.Text = "▲";
            this.hourUp.UseVisualStyleBackColor = true;
            this.hourUp.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // minDown
            // 
            this.minDown.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.minDown.Location = new System.Drawing.Point(262, 35);
            this.minDown.Name = "minDown";
            this.minDown.Size = new System.Drawing.Size(16, 27);
            this.minDown.TabIndex = 10;
            this.minDown.Text = "▼";
            this.minDown.UseVisualStyleBackColor = true;
            this.minDown.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // minUp
            // 
            this.minUp.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.minUp.Location = new System.Drawing.Point(262, 9);
            this.minUp.Name = "minUp";
            this.minUp.Size = new System.Drawing.Size(16, 27);
            this.minUp.TabIndex = 9;
            this.minUp.Text = "▲";
            this.minUp.UseVisualStyleBackColor = true;
            this.minUp.Click += new System.EventHandler(this.btnUpDown_Click);
            // 
            // btnOptions
            // 
            this.btnOptions.Font = new System.Drawing.Font("Tahoma", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.btnOptions.Location = new System.Drawing.Point(485, 7);
            this.btnOptions.Name = "btnOptions";
            this.btnOptions.Size = new System.Drawing.Size(16, 57);
            this.btnOptions.TabIndex = 13;
            this.btnOptions.Text = "▼";
            this.btnOptions.UseVisualStyleBackColor = true;
            this.btnOptions.Click += new System.EventHandler(this.btnOptions_Click);
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.button4);
            this.groupBox1.Controls.Add(this.cbWarnZeroTime);
            this.groupBox1.Controls.Add(this.btnMinus);
            this.groupBox1.Controls.Add(this.btnPlus);
            this.groupBox1.Controls.Add(this.tbDefaultTimeDelay);
            this.groupBox1.Controls.Add(this.comboDefaultAction);
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.cbMinimizeToTray);
            this.groupBox1.Controls.Add(this.cbRememberWinPos);
            this.groupBox1.Enabled = false;
            this.groupBox1.Location = new System.Drawing.Point(6, 73);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(494, 153);
            this.groupBox1.TabIndex = 13;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Options";
            // 
            // button4
            // 
            this.button4.Location = new System.Drawing.Point(358, 121);
            this.button4.Name = "button4";
            this.button4.Size = new System.Drawing.Size(119, 23);
            this.button4.TabIndex = 6;
            this.button4.Text = "About";
            this.button4.UseVisualStyleBackColor = true;
            // 
            // cbWarnZeroTime
            // 
            this.cbWarnZeroTime.AutoSize = true;
            this.cbWarnZeroTime.Checked = true;
            this.cbWarnZeroTime.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cbWarnZeroTime.Location = new System.Drawing.Point(10, 47);
            this.cbWarnZeroTime.Name = "cbWarnZeroTime";
            this.cbWarnZeroTime.Size = new System.Drawing.Size(219, 18);
            this.cbWarnZeroTime.TabIndex = 1;
            this.cbWarnZeroTime.Text = "Warn me if countdown time is zero";
            this.cbWarnZeroTime.UseVisualStyleBackColor = true;
            // 
            // btnMinus
            // 
            this.btnMinus.Location = new System.Drawing.Point(278, 121);
            this.btnMinus.Name = "btnMinus";
            this.btnMinus.Size = new System.Drawing.Size(41, 24);
            this.btnMinus.TabIndex = 5;
            this.btnMinus.Text = "-";
            this.btnMinus.TextAlign = System.Drawing.ContentAlignment.TopCenter;
            this.btnMinus.UseVisualStyleBackColor = true;
            this.btnMinus.Click += new System.EventHandler(this.btnMinus_Click);
            // 
            // btnPlus
            // 
            this.btnPlus.Location = new System.Drawing.Point(200, 121);
            this.btnPlus.Name = "btnPlus";
            this.btnPlus.Size = new System.Drawing.Size(39, 24);
            this.btnPlus.TabIndex = 4;
            this.btnPlus.Text = "+";
            this.btnPlus.TextAlign = System.Drawing.ContentAlignment.TopCenter;
            this.btnPlus.UseVisualStyleBackColor = true;
            this.btnPlus.Click += new System.EventHandler(this.btnPlus_Click);
            // 
            // tbDefaultTimeDelay
            // 
            this.tbDefaultTimeDelay.BackColor = System.Drawing.SystemColors.Window;
            this.tbDefaultTimeDelay.Location = new System.Drawing.Point(245, 122);
            this.tbDefaultTimeDelay.Name = "tbDefaultTimeDelay";
            this.tbDefaultTimeDelay.ReadOnly = true;
            this.tbDefaultTimeDelay.Size = new System.Drawing.Size(27, 22);
            this.tbDefaultTimeDelay.TabIndex = 6;
            this.tbDefaultTimeDelay.TabStop = false;
            this.tbDefaultTimeDelay.Text = "01";
            this.tbDefaultTimeDelay.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // comboDefaultAction
            // 
            this.comboDefaultAction.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboDefaultAction.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.comboDefaultAction.FormattingEnabled = true;
            this.comboDefaultAction.Items.AddRange(new object[] {
            "Shutdown",
            "Restart",
            "Logoff",
            "Lock",
            "Sleep",
            "Hibernate"});
            this.comboDefaultAction.Location = new System.Drawing.Point(201, 96);
            this.comboDefaultAction.Name = "comboDefaultAction";
            this.comboDefaultAction.Size = new System.Drawing.Size(117, 22);
            this.comboDefaultAction.TabIndex = 3;
            this.comboDefaultAction.SelectedIndexChanged += new System.EventHandler(this.cbDefaultAction_SelectedIndexChanged);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(7, 125);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(110, 14);
            this.label2.TabIndex = 4;
            this.label2.Text = "Default time delay:";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(7, 99);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(148, 14);
            this.label1.TabIndex = 3;
            this.label1.Text = "Default action on startup:";
            // 
            // cbMinimizeToTray
            // 
            this.cbMinimizeToTray.AutoSize = true;
            this.cbMinimizeToTray.Checked = true;
            this.cbMinimizeToTray.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cbMinimizeToTray.Location = new System.Drawing.Point(10, 73);
            this.cbMinimizeToTray.Name = "cbMinimizeToTray";
            this.cbMinimizeToTray.Size = new System.Drawing.Size(153, 18);
            this.cbMinimizeToTray.TabIndex = 2;
            this.cbMinimizeToTray.Text = "Minimize to system tray";
            this.cbMinimizeToTray.UseVisualStyleBackColor = true;
            // 
            // cbRememberWinPos
            // 
            this.cbRememberWinPos.AutoSize = true;
            this.cbRememberWinPos.Checked = true;
            this.cbRememberWinPos.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cbRememberWinPos.Location = new System.Drawing.Point(10, 21);
            this.cbRememberWinPos.Name = "cbRememberWinPos";
            this.cbRememberWinPos.Size = new System.Drawing.Size(178, 18);
            this.cbRememberWinPos.TabIndex = 0;
            this.cbRememberWinPos.Text = "Remember window position";
            this.cbRememberWinPos.UseVisualStyleBackColor = true;
            // 
            // notifyIcon1
            // 
            this.notifyIcon1.BalloonTipText = "Text 1";
            this.notifyIcon1.BalloonTipTitle = "Text 2";
            this.notifyIcon1.ContextMenuStrip = this.contextMenuStrip1;
            this.notifyIcon1.Icon = ((System.Drawing.Icon)(resources.GetObject("notifyIcon1.Icon")));
            this.notifyIcon1.Text = "Power Timer";
            this.notifyIcon1.MouseClick += new System.Windows.Forms.MouseEventHandler(this.notifyIcon1_MouseClick);
            // 
            // contextMenuStrip1
            // 
            this.contextMenuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripMenuItem1,
            this.toolStripMenuItem2});
            this.contextMenuStrip1.Name = "contextMenuStrip1";
            this.contextMenuStrip1.Size = new System.Drawing.Size(104, 48);
            // 
            // toolStripMenuItem1
            // 
            this.toolStripMenuItem1.Name = "toolStripMenuItem1";
            this.toolStripMenuItem1.Size = new System.Drawing.Size(103, 22);
            this.toolStripMenuItem1.Text = "Show";
            this.toolStripMenuItem1.Click += new System.EventHandler(this.toolStripMenuItem1_Click);
            // 
            // toolStripMenuItem2
            // 
            this.toolStripMenuItem2.Name = "toolStripMenuItem2";
            this.toolStripMenuItem2.Size = new System.Drawing.Size(103, 22);
            this.toolStripMenuItem2.Text = "Close";
            this.toolStripMenuItem2.Click += new System.EventHandler(this.toolStripMenuItem2_Click);
            // 
            // tabControl1
            // 
            this.tabControl1.Appearance = System.Windows.Forms.TabAppearance.Buttons;
            this.tabControl1.Controls.Add(this.tabPage2);
            this.tabControl1.Controls.Add(this.tabPage1);
            this.tabControl1.Font = new System.Drawing.Font("Tahoma", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.tabControl1.ItemSize = new System.Drawing.Size(117, 26);
            this.tabControl1.Location = new System.Drawing.Point(6, 8);
            this.tabControl1.Multiline = true;
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(120, 58);
            this.tabControl1.SizeMode = System.Windows.Forms.TabSizeMode.Fixed;
            this.tabControl1.TabIndex = 0;
            this.tabControl1.SelectedIndexChanged += new System.EventHandler(this.tabControl1_SelectedIndexChanged);
            // 
            // tabPage2
            // 
            this.tabPage2.Location = new System.Drawing.Point(4, 59);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage2.Size = new System.Drawing.Size(112, 0);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "Countdown";
            this.tabPage2.UseVisualStyleBackColor = true;
            // 
            // tabPage1
            // 
            this.tabPage1.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.tabPage1.Location = new System.Drawing.Point(4, 59);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage1.Size = new System.Drawing.Size(112, 0);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "Set time";
            this.tabPage1.UseVisualStyleBackColor = true;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 14F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(506, 70);
            this.Controls.Add(this.tabControl1);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.btnOptions);
            this.Controls.Add(this.minDown);
            this.Controls.Add(this.minUp);
            this.Controls.Add(this.hourDown);
            this.Controls.Add(this.hourUp);
            this.Controls.Add(this.secDown);
            this.Controls.Add(this.secUp);
            this.Controls.Add(this.cbAction);
            this.Controls.Add(this.tbSec);
            this.Controls.Add(this.tbMin);
            this.Controls.Add(this.tbHour);
            this.Controls.Add(this.btnStart);
            this.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.Fixed3D;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.Padding = new System.Windows.Forms.Padding(3, 5, 3, 3);
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Power Timer";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.Form1_FormClosed);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.TextChanged += new System.EventHandler(this.Form1_TextChanged);
            this.Resize += new System.EventHandler(this.Form1_Resize);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.contextMenuStrip1.ResumeLayout(false);
            this.tabControl1.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnStart;
        private System.Windows.Forms.Timer timer1;
        private System.Windows.Forms.ComboBox cbAction;
        private System.Windows.Forms.TextBox tbMin;
        private System.Windows.Forms.TextBox tbHour;
        private System.Windows.Forms.TextBox tbSec;
        private System.Windows.Forms.Button secUp;
        private System.Windows.Forms.Button secDown;
        private System.Windows.Forms.Button hourDown;
        private System.Windows.Forms.Button hourUp;
        private System.Windows.Forms.Button minDown;
        private System.Windows.Forms.Button minUp;
        private System.Windows.Forms.Button btnOptions;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.CheckBox cbMinimizeToTray;
        private System.Windows.Forms.CheckBox cbRememberWinPos;
        private System.Windows.Forms.TextBox tbDefaultTimeDelay;
        private System.Windows.Forms.ComboBox comboDefaultAction;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button btnMinus;
        private System.Windows.Forms.Button btnPlus;
        private System.Windows.Forms.CheckBox cbWarnZeroTime;
        private System.Windows.Forms.Button button4;
        private System.Windows.Forms.NotifyIcon notifyIcon1;
        private System.Windows.Forms.ContextMenuStrip contextMenuStrip1;
        private System.Windows.Forms.ToolStripMenuItem toolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem toolStripMenuItem2;
        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tabPage2;
        private System.Windows.Forms.TabPage tabPage1;

    }
}

