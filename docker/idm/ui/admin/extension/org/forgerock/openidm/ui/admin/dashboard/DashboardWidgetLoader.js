"use strict";

/*
 * Copyright 2015-2018 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define(["jquery", "underscore", "org/forgerock/openidm/ui/admin/util/AdminAbstractView", "org/forgerock/commons/ui/common/main/EventManager", "org/forgerock/commons/ui/common/util/Constants", "org/forgerock/commons/ui/common/main/Configuration", "org/forgerock/openidm/ui/common/delegates/ConfigDelegate", "org/forgerock/openidm/ui/common/dashboard/widgets/MemoryUsageWidget", "org/forgerock/openidm/ui/common/dashboard/widgets/CPUUsageWidget", "org/forgerock/openidm/ui/common/dashboard/widgets/FullHealthWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/MappingReconResultsWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/ResourceListWidget", "org/forgerock/openidm/ui/common/dashboard/widgets/QuickStartWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/FrameWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/RelationshipWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/ClusterStatusWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/AuditDataOverTimeWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/ManagedObjectsWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/SocialRegistrationOverTimeWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/SocialLoginCountWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/MetricsWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/GraphWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/CounterWidget", "org/forgerock/openidm/ui/admin/dashboard/widgets/HistoricReportWidget"], function ($, _, AdminAbstractView, eventManager, constants, conf, ConfigDelegate, MemoryUsageWidget, CPUUsageWidget, FullHealthWidget, MappingReconResultsWidget, ResourceListWidget, QuickStartWidget, FrameWidget, RelationshipWidget, ClusterStatusWidget, AuditDataOverTimeWidget, ManagedObjectsWidget, SocialRegistrationOverTimeWidget, SocialLoginCountWidget, MetricsWidget, GraphWidget, CounterWidget, HistoricReportWidget) {

    var dwlInstance = {},
        widgetList = {
        lifeCycleMemoryHeap: {
            name: $.t("dashboard.memoryUsageHeap"),
            widget: MemoryUsageWidget,
            desc: $.t("dashboard.widgetDescriptions.lifeCycleMemoryHeap"),
            defaultSize: "small",
            group: $.t('dashboard.widgetGroups.systemStatus')
        },
        lifeCycleMemoryNonHeap: {
            name: $.t("dashboard.memoryUsageNonHeap"),
            widget: MemoryUsageWidget,
            desc: $.t("dashboard.widgetDescriptions.lifeCycleMemoryNonHeap"),
            defaultSize: "small",
            group: $.t('dashboard.widgetGroups.systemStatus')
        },
        systemHealthFull: {
            name: $.t("dashboard.systemHealth"),
            widget: FullHealthWidget,
            desc: $.t("dashboard.widgetDescriptions.systemHealthFull"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.systemStatus')
        },
        cpuUsage: {
            name: $.t("dashboard.cpuUsage"),
            widget: CPUUsageWidget,
            desc: $.t("dashboard.widgetDescriptions.cpuUsage"),
            defaultSize: "small",
            group: $.t('dashboard.widgetGroups.systemStatus')
        },
        lastRecon: {
            name: $.t("dashboard.lastReconciliation"),
            widget: MappingReconResultsWidget,
            desc: $.t("dashboard.widgetDescriptions.lastRecon"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.reporting')
        },
        resourceList: {
            name: $.t("dashboard.resources"),
            widget: ResourceListWidget,
            desc: $.t("dashboard.widgetDescriptions.resourceList"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.reporting')
        },
        quickStart: {
            name: $.t("dashboard.quickStart.quickStartTitle"),
            widget: QuickStartWidget,
            desc: $.t("dashboard.widgetDescriptions.quickStart"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.utils')
        },
        frame: {
            name: $.t("dashboard.frameWidget.frameWidgetTitle"),
            widget: FrameWidget,
            desc: $.t("dashboard.widgetDescriptions.frame"),
            defaultSize: "large",
            embeddedDashboard: false,
            group: $.t('dashboard.widgetGroups.utils')
        },
        relationship: {
            name: $.t("dashboard.relationshipWidget.relationshipTitle"),
            widget: RelationshipWidget,
            desc: $.t("dashboard.widgetDescriptions.relationship"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.utils')
        },
        clusterStatus: {
            name: $.t("dashboard.clusterStatusWidget.clusterStatusTitle"),
            widget: ClusterStatusWidget,
            desc: $.t("dashboard.widgetDescriptions.clusterStatus"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.systemStatus')
        },
        audit: {
            name: $.t("dashboard.auditData.widgetTitle"),
            widget: AuditDataOverTimeWidget,
            desc: $.t("dashboard.widgetDescriptions.auditData"),
            defaultSize: "large",
            defaults: {
                minRange: "#b0d4cd",
                maxRange: "#24423c",
                legendRange: {
                    week: [10, 30, 90, 270, 810],
                    month: [500, 2500, 5000],
                    year: [10000, 40000, 100000, 250000]
                }
            },
            group: $.t('dashboard.widgetGroups.reporting')
        },
        // socialLogin: {
        //     name: $.t("dashboard.socialDetailsWidget.dailyLogin"),
        //     widget: SocialLoginCountWidget,
        //     desc: $.t("dashboard.widgetDescriptions.dailyLogin"),
        //     defaultSize: "small",
        //     group: $.t('dashboard.widgetGroups.social')
        // },
        // socialRegistrationOverTime: {
        //     name: $.t("dashboard.socialRegistrationOverTime.socialRegistrationOverTimeTitle"),
        //     widget: SocialRegistrationOverTimeWidget,
        //     desc: $.t("dashboard.widgetDescriptions.socialRegistrationOverTime"),
        //     defaultSize: "large",
        //     group: $.t('dashboard.widgetGroups.social')
        // },
        ManagedObjects: {
            name: $.t("dashboard.managedObjectsWidget.managedObjectsTitle"),
            widget: ManagedObjectsWidget,
            desc: $.t("dashboard.widgetDescriptions.managedObjects"),
            defaultSize: "large",
            group: $.t('dashboard.widgetGroups.utils')
        },
        GraphWidget: {
            name: $.t("dashboard.graphWidget.graphWidgetTitle"),
            widget: GraphWidget,
            desc: $.t("dashboard.widgetDescriptions.graphWidget"),
            defaultSize: "large",
            defaults: {
                resource: "user",
                metric: "accountStatus",
                graphType: "bar",
                widgetTitle: $.t("dashboard.graphWidget.graphWidgetTitle")
            },
            group: $.t('dashboard.widgetGroups.reporting')
        },
        counter: {
            name: $.t("dashboard.counterWidget.counterWidgetTitle"),
            widget: CounterWidget,
            desc: $.t("dashboard.widgetDescriptions.counterWidget"),
            defaultSize: "x-small",
            defaultOptionSelect: "activeUsers",
            group: $.t('dashboard.widgetGroups.reporting')
        },
        // passwordResets: {
        //     name: $.t('dashboard.historicalReportWidget.passwordResets.title'),
        //     widget: HistoricReportWidget,
        //     desc: $.t('dashboard.historicalReportWidget.passwordResets.desc'),
        //     defaultSize: "x-small",
        //     group: $.t('dashboard.widgetGroups.reporting'),
        //     defaults: {
        //         widgetTitle: $.t('dashboard.historicalReportWidget.passwordResets.title'),
        //         graphType: "fa-bar-chart"
        //     },
        //     config: {
        //         graphTypes: ["fa-line-chart", "fa-bar-chart"],
        //         socialQuery: 'and passwordChanged eq true and operation eq "PATCH"',
        //         auditType: "activity",
        //         aggregateFields: "TIMESTAMP=/timestamp;scale:day;utcOffset:0000",
        //         serviceEnabled: function serviceEnabled() {
        //             var promise = $.Deferred();
        //             ConfigDelegate.readEntity("selfservice/reset").then(function () {
        //                 promise.resolve(true);
        //             }, function () {
        //                 promise.resolve(false);
        //             });
        //             return promise;
        //         },
        //         configServiceLink: "#selfservice/passwordreset/",
        //         configServiceText: $.t('dashboard.historicalReportWidget.passwordResets.enableBtnText'),
        //         configServiceDesc: $.t('dashboard.historicalReportWidget.passwordResets.enableDesc'),
        //         removeUnusedProvider: false
        //     }
        // },
        // signIns: {
        //     name: $.t('dashboard.historicalReportWidget.signIns.title'),
        //     widget: HistoricReportWidget,
        //     desc: $.t('dashboard.historicalReportWidget.signIns.desc'),
        //     defaultSize: "x-small",
        //     group: $.t('dashboard.widgetGroups.reporting'),
        //     defaults: {
        //         widgetTitle: $.t('dashboard.historicalReportWidget.signIns.title'),
        //         providers: ["Username/Password"],
        //         graphType: "fa-pie-chart"
        //     },
        //     config: {
        //         graphTypes: ["fa-line-chart", "fa-bar-chart", "fa-pie-chart"],
        //         socialQuery: 'and !(eventName eq "SESSION") and !(eventName eq "FAILED")',
        //         auditType: "authentication",
        //         aggregateFields: "TIMESTAMP=/timestamp;scale:day;utcOffset:0000,VALUE=/context,VALUE=/provider",
        //         cleanData: function cleanData(data) {
        //             return _.filter(data, function (record) {
        //                 return record.context.moduleId !== "INTERNAL_USER";
        //             });
        //         },
        //         serviceEnabled: function serviceEnabled() {
        //             return true;
        //         },
        //         removeUnusedProvider: true
        //     }
        // },
        // newRegistrations: {
        //     name: $.t('dashboard.historicalReportWidget.newReg.title'),
        //     widget: HistoricReportWidget,
        //     desc: $.t('dashboard.historicalReportWidget.newReg.desc'),
        //     defaultSize: "x-small",
        //     group: $.t('dashboard.widgetGroups.reporting'),
        //     defaults: {
        //         widgetTitle: $.t('dashboard.historicalReportWidget.newReg.title'),
        //         providers: ["Username/Password"],
        //         graphType: "fa-line-chart"
        //     },
        //     config: {
        //         graphTypes: ["fa-line-chart", "fa-bar-chart", "fa-pie-chart"],
        //         socialQuery: 'and context pr and objectId sw "managed/user"',
        //         auditType: "activity",
        //         aggregateFields: "TIMESTAMP=/timestamp;scale:day;utcOffset:0000,VALUE=/context,VALUE=/provider",
        //         serviceEnabled: function serviceEnabled() {
        //             var promise = $.Deferred();
        //             ConfigDelegate.readEntity("selfservice/registration").then(function () {
        //                 promise.resolve(true);
        //             }, function () {
        //                 promise.resolve(false);
        //             });
        //             return promise;
        //         },
        //         configServiceLink: "#selfservice/userregistration/",
        //         configServiceText: $.t('dashboard.historicalReportWidget.newReg.enableBtnText'),
        //         configServiceDesc: $.t('dashboard.historicalReportWidget.newReg.enableDesc'),
        //         removeUnusedProvider: true
        //     }
        // }
    },
        DashboardWidgetLoader = AdminAbstractView.extend({
        template: "templates/dashboard/DashboardWidgetLoaderTemplate.html",
        noBaseTemplate: true,
        model: {},
        data: {},

        render: function render(args, callback) {
            this.element = args.element;

            this.data.widgetType = args.widget.type;
            this.data.widget = widgetList[args.widget.type];

            this.parentRender(_.bind(function () {
                args.element = this.$el.find(".widget");
                args.title = this.data.widget.name;
                args.showConfigButton = true;
                args.widgetConfig = widgetList[this.data.widgetType].config;

                this.model.widget = widgetList[this.data.widgetType].widget.generateWidget(args, callback);
            }, this));
        }
    });

    dwlInstance.generateWidget = function (loadingObject, callback) {
        var widget = {};

        $.extend(true, widget, new DashboardWidgetLoader());

        widget.render(loadingObject, callback);

        return widget;
    };

    dwlInstance.getWidgetList = function () {
        return ConfigDelegate.readEntity("metrics").then(function (response) {
            if (response.enabled && !$("#dashboardWidgets #metricsTable:visible").length) {
                widgetList.Metrics = {
                    name: $.t("dashboard.metricsWidget.metricsTitle"),
                    widget: MetricsWidget,
                    desc: $.t("dashboard.widgetDescriptions.metrics"),
                    defaultSize: "large",
                    group: $.t('dashboard.widgetGroups.reporting')
                };
            } else {
                delete widgetList.Metrics;
            }

            return widgetList;
        });
    };

    return dwlInstance;
});
