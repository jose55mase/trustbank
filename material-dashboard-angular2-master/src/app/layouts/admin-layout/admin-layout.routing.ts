import { Routes } from '@angular/router';

import { DashboardComponent } from '../../dashboard/dashboard.component';
import { UserProfileComponent } from '../../user-profile/user-profile.component';
import { TableListComponent } from '../../table-list/table-list.component';
import { TypographyComponent } from '../../typography/typography.component';
import { IconsComponent } from '../../icons/icons.component';
import { MapsComponent } from '../../maps/maps.component';
import { NotificationsComponent } from '../../notifications/notifications.component';
import { UpgradeComponent } from '../../upgrade/upgrade.component';
import { TransactionComponent } from 'app/transaction/transaction.component';
import { AccountsComponent } from 'app/accounts/accounts.component';
import { FilesComponent } from 'app/files/files.component';
import { LoginComponent } from 'app/login/login.component';

import { AdminTransactionComponent } from 'app/transaction/admin-transaction/admin-transaction.component';
import { AdminUserProfileComponent } from 'app/user-profile/profile/admin-user-profile/admin-user-profile.component';


export const AdminLayoutRoutes: Routes = [
    // {
    //   path: '',
    //   children: [ {
    //     path: 'dashboard',
    //     component: DashboardComponent
    // }]}, {
    // path: '',
    // children: [ {
    //   path: 'userprofile',
    //   component: UserProfileComponent
    // }]
    // }, {
    //   path: '',
    //   children: [ {
    //     path: 'icons',
    //     component: IconsComponent
    //     }]
    // }, {
    //     path: '',
    //     children: [ {
    //         path: 'notifications',
    //         component: NotificationsComponent
    //     }]
    // }, {
    //     path: '',
    //     children: [ {
    //         path: 'maps',
    //         component: MapsComponent
    //     }]
    // }, {
    //     path: '',
    //     children: [ {
    //         path: 'typography',
    //         component: TypographyComponent
    //     }]
    // }, {
    //     path: '',
    //     children: [ {
    //         path: 'upgrade',
    //         component: UpgradeComponent
    //     }]
    // }
    { path: 'dashboard',        component: DashboardComponent },
    { path: 'transaction',      component: TransactionComponent },
    { path: 'accounts',         component: AccountsComponent },
    { path: 'files',            component: FilesComponent },
    

    { path: 'admin-transaction',component: AdminTransactionComponent },
    { path: 'admin-profiles'   ,component: AdminUserProfileComponent },

    { path: 'user-profile',     component: UserProfileComponent },
    { path: 'table-list',       component: TableListComponent },
    { path: 'typography',       component: TypographyComponent },
    { path: 'icons',            component: IconsComponent },
    { path: 'maps',             component: MapsComponent },
    { path: 'notifications',    component: NotificationsComponent },
    { path: 'upgrade',          component: UpgradeComponent },
];
