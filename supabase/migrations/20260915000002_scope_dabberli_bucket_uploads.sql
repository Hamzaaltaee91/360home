-- Security fix (2026-09-15, follow-up to 20260915000001): the public
-- `dabberli` storage bucket's INSERT policy only checked
-- `bucket_id = 'dabberli'`, with no per-user/per-owner path scoping. Any
-- authenticated user could write/squat files under another user's
-- property-photos/<requestId>/..., profile-pictures/<userId>/..., or
-- offer-photos/<offerId>/... prefix.
--
-- The three prefixes actually written by the app (confirmed via
-- lib/services/supabase_service.dart:uploadPropertyPhoto/
-- uploadProfilePicture and site/js/offers.js:uploadOfferPhotos):
--   property-photos/<requestId>/<file>  — uploader must own that request
--   profile-pictures/<userId>/<file>    — uploader must be that user
--   offer-photos/<offerId>/<file>       — uploader must own that offer
--
-- Follows the same storage.foldername(name) pattern already used
-- correctly by verification_documents_owner_insert.

DROP POLICY IF EXISTS "dabberli_authenticated_insert" ON storage.objects;

CREATE POLICY "dabberli_authenticated_insert" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'dabberli'
    AND (
      (
        (storage.foldername(name))[1] = 'profile-pictures'
        AND (storage.foldername(name))[2] = public.current_user_id()::text
      )
      OR (
        (storage.foldername(name))[1] = 'property-photos'
        AND EXISTS (
          SELECT 1 FROM public.property_requests
          WHERE id::text = (storage.foldername(name))[2]
            AND buyer_id = public.current_user_id()
        )
      )
      OR (
        (storage.foldername(name))[1] = 'offer-photos'
        AND EXISTS (
          SELECT 1 FROM public.realtor_offers
          WHERE id::text = (storage.foldername(name))[2]
            AND realtor_id = public.current_user_id()
        )
      )
    )
  );
