import argparse

from pruner import disk, registry, backup

def run_registry(args):
    registry.prune_registry()
def run_disks(args):
    disk.prune_disks()
def run_backup(args):
    backup.run_backup(args.source_registry, args.target_registry)

def main():
    parser = argparse.ArgumentParser(description='gcp pruner')
    subparsers = parser.add_subparsers()

    disk_parser = subparsers.add_parser('disk', help='prune unattached disks')
    disk_parser.set_defaults(func=run_disks)

    registry_parser = subparsers.add_parser('registry',
                                            help='prune images from registry')
    registry_parser.set_defaults(func=run_registry)

    backup_parser = subparsers.add_parser('backup')
    backup_parser.add_argument('source-repository',
                               help='sorce to backup from')
    backup_parser.add_argument('target-repository',
                               help='target to backup to')
    backup_parser.set_defaults(func=run_backup)

    args = parser.parse_args()
    args.func(args)

if __name__ == '__main__':
    main()
