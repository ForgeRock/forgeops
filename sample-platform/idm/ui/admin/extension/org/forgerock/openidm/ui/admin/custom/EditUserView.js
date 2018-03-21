/*
 * Copyright 2015-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define([
    "lodash",
    "org/forgerock/commons/ui/common/main/AbstractView",
    "org/forgerock/openidm/ui/admin/user/EditUserView",
    "./PolicyTree"
], function (_, AbstractView, defaultEditUserView, PolicyTree) {

    var EditUserView = function () {
        return AbstractView.apply(this, arguments);
    };

    EditUserView.prototype = Object.create(defaultEditUserView);

    EditUserView.prototype.render = function (args, callback) {
        defaultEditUserView.render.call(this, args, _.bind(function () {
            var allowedFields = PolicyTree.getAllowedFieldsToPatch('managed/user/*');
            if (allowedFields) {
                this.$el.find(":input.form-control").prop('readonly', true)
                allowedFields.forEach(_.bind(function (field) {
                    this.$el.find(".container-" + field + " :input").prop('readonly', false);
                }, this));
                // select boxes need to be disabled rather than set to readonly
                this.$el.find("select.form-control").prop('disabled', true);
                allowedFields.forEach(_.bind(function (field) {
                    this.$el.find(".container-" + field + " select").prop('disabled', false);
                }, this));

                if (_.indexOf(allowedFields, 'password') !== -1) {
                    this.$el.find("#input-password").prop('readonly', false);
                    this.$el.find("#input-confirmPassword").prop('readonly', false);
                }
            }
            callback();

        }, this));
    };

    EditUserView.prototype.getResetPasswordScriptAvailable = function () {
        return this.resetPasswordScriptAvailable && PolicyTree.evaluate('managed/user/*?_action=resetPassword');
    };

    return new EditUserView();
});
