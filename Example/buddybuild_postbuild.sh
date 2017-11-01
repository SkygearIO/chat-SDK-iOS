#!/usr/bin/env bash

echo "Uploading ipa to HockeyApp..."

if [[ "$BUDDYBUILD_SCHEME" =~ "Swift Example" ]]; then
    cd $BUDDYBUILD_PRODUCT_DIR
    find . -name "*.dSYM" -print | zip /tmp/dsyms.zip -@
    curl https://rink.hockeyapp.net/api/2/apps/$HOCKEYAPP_APPID/app_versions/upload \
        -F "status=2" \
        -F "notify=0" \
        -F "notes=$RELEASE_NOTES" \
        -F "notes_type=0" \
        -F "ipa=@$BUDDYBUILD_IPA_PATH" \
        -F "dsym=@/tmp/dsyms.zip" \
        -H "X-HockeyAppToken: $HOCKEYAPP_APPTOKEN"
else
    echo "Only upload Swift Example target to HockeyApp."
fi
